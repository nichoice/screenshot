import AppKit
import AVFoundation
import Foundation
import ScreenCaptureKit

typealias RecordingCompletion = (_ url: URL?, _ error: Error?) -> Void

@MainActor
protocol MacShotRecordingEngine: AnyObject {
    func startRecording(
        rect: NSRect,
        screen: NSScreen,
        excludeWindowNumbers: [CGWindowID],
        completion: @escaping RecordingCompletion
    )

    func stopRecording()
}

@MainActor
final class ScreenCaptureKitRecordingEngine: NSObject, MacShotRecordingEngine {
    enum RecordingError: LocalizedError {
        case noDisplay
        case noOutput
        case noFrames
        case invalidSize
        case writerInputUnavailable

        var errorDescription: String? {
            switch self {
            case .noDisplay:
                return "Could not find the screen to record."
            case .noOutput:
                return "Could not create output file."
            case .noFrames:
                return "No video frames were recorded."
            case .invalidSize:
                return "Recording area is too small."
            case .writerInputUnavailable:
                return "Could not configure the video writer."
            }
        }
    }

    private enum State {
        case idle
        case recording
        case stopping
    }

    private var state: State = .idle
    private var stream: SCStream?
    private var streamOutput: RecordingStreamOutput?
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private let recordingQueue = DispatchQueue(label: "screenshottool.recording")
    private var outputURL: URL?
    private var completion: RecordingCompletion?
    private var sessionStarted = false
    private var fps = 30

    static func sourceRect(for rect: NSRect, in screenFrame: NSRect) -> CGRect {
        CGRect(
            x: rect.minX - screenFrame.minX,
            y: screenFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    func startRecording(
        rect: NSRect,
        screen: NSScreen,
        excludeWindowNumbers: [CGWindowID],
        completion: @escaping RecordingCompletion
    ) {
        guard state == .idle else { return }
        guard rect.width >= 8, rect.height >= 8 else {
            completion(nil, RecordingError.invalidSize)
            return
        }

        self.completion = completion
        state = .recording
        let defaultsFPS = UserDefaults.standard.integer(forKey: "recordingFPS")
        fps = defaultsFPS > 0 ? defaultsFPS : 30

        Task {
            await beginCapture(rect: rect, screen: screen, excludeWindowNumbers: excludeWindowNumbers)
        }
    }

    func stopRecording() {
        guard state == .recording else { return }
        state = .stopping
        Task { await finalizeCapture() }
    }

    private func beginCapture(rect: NSRect, screen: NSScreen, excludeWindowNumbers: [CGWindowID]) async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let screenID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
            guard let display = content.displays.first(where: { screenID != nil && $0.displayID == screenID! })
                    ?? content.displays.first else {
                fail(RecordingError.noDisplay)
                return
            }

            let excludedWindows = excludeWindowNumbers.compactMap { windowID in
                content.windows.first(where: { CGWindowID($0.windowID) == windowID })
            }
            let sourceRect = Self.sourceRect(for: rect, in: screen.frame)
            let config = SCStreamConfiguration()
            config.width = Int(sourceRect.width * screen.backingScaleFactor)
            config.height = Int(sourceRect.height * screen.backingScaleFactor)
            guard config.width > 0, config.height > 0 else {
                fail(RecordingError.invalidSize)
                return
            }

            config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
            config.showsCursor = true
            config.sourceRect = sourceRect
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.scalesToFit = false
            config.colorSpaceName = CGColorSpace.sRGB
            config.capturesAudio = false

            let outputURL = makeOutputURL()
            self.outputURL = outputURL
            try setupWriter(url: outputURL, width: config.width, height: config.height)

            let output = RecordingStreamOutput()
            output.onFrame = { [weak self] pixelBuffer, presentationTime in
                self?.writeFrame(pixelBuffer: pixelBuffer, presentationTime: presentationTime)
            }
            output.onStopped = { [weak self] error in
                guard let error else { return }
                Task { @MainActor in
                    self?.fail(error)
                }
            }
            streamOutput = output

            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            let stream = SCStream(filter: filter, configuration: config, delegate: output)
            try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: recordingQueue)
            try await stream.startCapture()
            self.stream = stream
        } catch {
            fail(error)
        }
    }

    private func finalizeCapture() async {
        if let stream {
            try? await stream.stopCapture()
            self.stream = nil
        }
        streamOutput = nil
        await finishWriter()
    }

    private func setupWriter(url: URL, width: Int, height: Int) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: max(width * height * 8, 2_000_000),
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps * 2,
            ],
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else {
            throw RecordingError.writerInputUnavailable
        }

        let sourceAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourceAttributes
        )
        writer.add(input)
        writer.startWriting()

        self.writer = writer
        self.videoInput = input
        self.adaptor = adaptor
        self.sessionStarted = false
    }

    private func writeFrame(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        guard state == .recording,
              let writer,
              let videoInput,
              let adaptor,
              videoInput.isReadyForMoreMediaData
        else { return }

        if !sessionStarted {
            writer.startSession(atSourceTime: presentationTime)
            sessionStarted = true
        }
        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }

    private func finishWriter() async {
        guard let writer, let videoInput else {
            fail(RecordingError.noOutput)
            return
        }
        guard sessionStarted else {
            writer.cancelWriting()
            fail(RecordingError.noFrames)
            return
        }

        videoInput.markAsFinished()
        await writer.finishWriting()
        if writer.status == .failed {
            fail(writer.error ?? RecordingError.noOutput)
        } else {
            succeed()
        }
    }

    private func makeOutputURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss.SSS"
        let baseName = "SnapPii Recording \(formatter.string(from: Date()))"
        let directory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        var url = directory.appendingPathComponent("\(baseName).mp4")
        var suffix = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = directory.appendingPathComponent("\(baseName) \(suffix).mp4")
            suffix += 1
        }
        return url
    }

    private func succeed() {
        state = .idle
        let url = outputURL
        let completion = completion
        reset()
        completion?(url, nil)
    }

    private func fail(_ error: Error) {
        state = .idle
        let completion = completion
        writer?.cancelWriting()
        reset()
        completion?(nil, error)
    }

    private func reset() {
        stream = nil
        streamOutput = nil
        writer = nil
        videoInput = nil
        adaptor = nil
        outputURL = nil
        completion = nil
        sessionStarted = false
    }
}

private final class RecordingStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    var onFrame: ((CVPixelBuffer, CMTime) -> Void)?
    var onStopped: ((Error?) -> Void)?

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let pixelBuffer = sampleBuffer.imageBuffer else { return }
        onFrame?(pixelBuffer, CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onStopped?(error)
    }
}
