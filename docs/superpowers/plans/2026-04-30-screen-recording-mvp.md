# Screen Recording MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a working area screen-recording MVP to the imported MacShot capture flow so users can select a region, start recording, stop it, and receive an MP4 file.

**Architecture:** Keep the current screenshot flow intact and add a narrow recording path behind `MacShotCoreFeatureFlags.recordingEnabled`. `MacShotCaptureSession` owns a new `MacShotRecordingEngine` abstraction; the default implementation records the selected region with ScreenCaptureKit and AVAssetWriter, while tests inject a spy implementation. The first MVP excludes system audio, microphone, webcam, keystroke overlay, pause/resume, and advanced export routing.

**Tech Stack:** Swift/AppKit, ScreenCaptureKit, AVFoundation, XCTest, XcodeGen.

---

### Task 1: Recording Result Model and Engine Boundary

**Files:**
- Modify: `MacShotCore/MacShotCaptureResult.swift`
- Create: `MacShotCore/Imported/Capture/MacShotRecordingEngine.swift`
- Test: `MacShotCoreTests/MacShotCaptureSessionRecordingTests.swift`

- [ ] **Step 1: Write a failing session-level test**

Create `MacShotCoreTests/MacShotCaptureSessionRecordingTests.swift` with:

```swift
import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionRecordingTests: XCTestCase {
    func testStartRecordingDelegatesToRecordingEngineAndCompletesWithURL() {
        let engine = SpyRecordingEngine()
        let expectedURL = URL(fileURLWithPath: "/tmp/ScreenshotTool-recording.mp4")
        var completedResult: MacShotCaptureResult?
        let session = MacShotCaptureSession(
            preferences: .default,
            presentsOverlay: false,
            onComplete: { completedResult = $0 },
            recordingEngineFactory: { engine }
        )

        XCTAssertTrue(session.start())
        let screen = NSScreen.main ?? NSScreen.screens[0]
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 20, y: 30, width: 400, height: 240),
            screen: screen
        )

        XCTAssertEqual(engine.startedRect, NSRect(x: 20, y: 30, width: 400, height: 240))
        XCTAssertEqual(engine.startedScreen, screen)
        XCTAssertEqual(session.state, .recording)

        engine.completion?(expectedURL, nil)

        XCTAssertEqual(session.state, .completed)
        XCTAssertEqual(completedResult?.recordingURL, expectedURL)
        XCTAssertNil(completedResult?.image)
    }

    func testStopRecordingDelegatesToActiveRecordingEngine() {
        let engine = SpyRecordingEngine()
        let session = MacShotCaptureSession(
            preferences: .default,
            presentsOverlay: false,
            recordingEngineFactory: { engine }
        )
        let screen = NSScreen.main ?? NSScreen.screens[0]

        XCTAssertTrue(session.start())
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 1, y: 2, width: 120, height: 80),
            screen: screen
        )
        session.overlayDidRequestStopRecording(OverlayWindowController(screen: screen))

        XCTAssertEqual(engine.stopCount, 1)
    }
}

@MainActor
private final class SpyRecordingEngine: MacShotRecordingEngine {
    var completion: RecordingCompletion?
    var startedRect: NSRect?
    var startedScreen: NSScreen?
    var stopCount = 0

    func startRecording(
        rect: NSRect,
        screen: NSScreen,
        excludeWindowNumbers: [CGWindowID],
        completion: @escaping RecordingCompletion
    ) {
        self.startedRect = rect
        self.startedScreen = screen
        self.completion = completion
    }

    func stopRecording() {
        stopCount += 1
    }
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionRecordingTests
```

Expected: compile failure because `MacShotRecordingEngine`, `recordingEngineFactory`, `.recording`, and `recordingURL` do not exist yet.

- [ ] **Step 3: Add the model and protocol**

In `MacShotCore/MacShotCaptureResult.swift`, allow a result to hold either an image or recording URL:

```swift
public struct MacShotCaptureResult: Equatable {
    public let image: NSImage?
    public let recordingURL: URL?
    public let capturedAt: Date

    public init(image: NSImage, capturedAt: Date = Date()) {
        self.image = image
        self.recordingURL = nil
        self.capturedAt = capturedAt
    }

    public init(recordingURL: URL, capturedAt: Date = Date()) {
        self.image = nil
        self.recordingURL = recordingURL
        self.capturedAt = capturedAt
    }
}
```

Create `MacShotCore/Imported/Capture/MacShotRecordingEngine.swift` with:

```swift
import AppKit
import Foundation

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
```

- [ ] **Step 4: Wire the session to the protocol**

Modify `MacShotCore/MacShotCaptureSession.swift`:

```swift
public enum State: Equatable {
    case idle
    case running
    case recording
    case cancelled
    case completed
}
```

Add stored properties:

```swift
private let recordingEngineFactory: () -> MacShotRecordingEngine
private var recordingEngine: MacShotRecordingEngine?
```

Extend the internal initializer with:

```swift
recordingEngineFactory: @escaping () -> MacShotRecordingEngine = { ScreenCaptureKitRecordingEngine() }
```

Set `self.recordingEngineFactory = recordingEngineFactory`.

Replace empty recording delegate methods with:

```swift
func overlayDidRequestStartRecording(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {
    guard state == .running else { return }
    let engine = recordingEngineFactory()
    recordingEngine = engine
    state = .recording
    let excludedWindowNumbers = overlayControllers.map(\.windowNumber)
    dismissOverlayControllers()
    engine.startRecording(rect: rect, screen: screen, excludeWindowNumbers: excludedWindowNumbers) { [weak self] url, error in
        guard let self else { return }
        if let url {
            let captureResult = MacShotCaptureResult(recordingURL: url)
            self.result = captureResult
            self.state = .completed
            self.recordingEngine = nil
            self.onComplete?(captureResult)
        } else {
            self.recordingEngine = nil
            _ = self.cancel()
        }
    }
}

func overlayDidRequestStopRecording(_ controller: OverlayWindowController) {
    recordingEngine?.stopRecording()
}
```

- [ ] **Step 5: Run the session tests**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionRecordingTests
```

Expected: tests compile and pass once Task 2 creates the default `ScreenCaptureKitRecordingEngine`.

### Task 2: ScreenCaptureKit MP4 Recording Engine

**Files:**
- Modify: `MacShotCore/Imported/Capture/MacShotRecordingEngine.swift`
- Test: `MacShotCoreTests/MacShotRecordingGeometryTests.swift`

- [ ] **Step 1: Write a geometry test**

Create `MacShotCoreTests/MacShotRecordingGeometryTests.swift`:

```swift
import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotRecordingGeometryTests: XCTestCase {
    func testSourceRectConvertsAppKitScreenRectToScreenCaptureKitRect() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let rect = NSRect(x: 100, y: 120, width: 640, height: 360)

        let sourceRect = ScreenCaptureKitRecordingEngine.sourceRect(for: rect, in: screenFrame)

        XCTAssertEqual(sourceRect.origin.x, 100)
        XCTAssertEqual(sourceRect.origin.y, 420)
        XCTAssertEqual(sourceRect.width, 640)
        XCTAssertEqual(sourceRect.height, 360)
    }
}
```

- [ ] **Step 2: Run the geometry test to confirm it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotRecordingGeometryTests
```

Expected: compile failure because `ScreenCaptureKitRecordingEngine` does not exist.

- [ ] **Step 3: Implement the default recording engine**

Append to `MacShotCore/Imported/Capture/MacShotRecordingEngine.swift` a `ScreenCaptureKitRecordingEngine` adapted from macshot's `RecordingEngine`, limited to screen-only MP4:

```swift
import AVFoundation
import ScreenCaptureKit

@MainActor
final class ScreenCaptureKitRecordingEngine: NSObject, MacShotRecordingEngine {
    enum RecordingError: LocalizedError {
        case noDisplay
        case noOutput
        case invalidSize

        var errorDescription: String? {
            switch self {
            case .noDisplay: "Could not find the screen to record."
            case .noOutput: "Could not create output file."
            case .invalidSize: "Recording area is too small."
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
        fps = UserDefaults.standard.integer(forKey: "recordingFPS") > 0
            ? UserDefaults.standard.integer(forKey: "recordingFPS")
            : 30
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
            let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            guard let display = content.displays.first(where: { screenID != nil && $0.displayID == screenID! })
                    ?? content.displays.first else {
                fail(RecordingError.noDisplay)
                return
            }

            let excludedWindows = excludeWindowNumbers.compactMap { id in
                content.windows.first(where: { CGWindowID($0.windowID) == id })
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
            if #available(macOS 14.0, *) {
                config.colorSpaceName = CGColorSpace.sRGB
            }
            if #available(macOS 13.0, *) {
                config.capturesAudio = false
            }

            let outputURL = makeOutputURL()
            self.outputURL = outputURL
            try setupWriter(url: outputURL, width: config.width, height: config.height)

            let output = RecordingStreamOutput()
            output.onFrame = { [weak self] pixelBuffer, presentationTime in
                self?.writeFrame(pixelBuffer: pixelBuffer, presentationTime: presentationTime)
            }
            output.onStopped = { [weak self] error in
                guard let self else { return }
                if let error {
                    Task { @MainActor in self.fail(error) }
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
            succeed()
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
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = "Recording \(formatter.string(from: Date())).mp4"
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?
            .appendingPathComponent(name)
            ?? FileManager.default.temporaryDirectory.appendingPathComponent(name)
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
        reset()
        completion?(nil, error)
    }

    private func reset() {
        stream = nil
        streamOutput = nil
        writer = nil
        videoInput = nil
        adaptor = nil
        completion = nil
        outputURL = nil
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
```

- [ ] **Step 4: Run the geometry and session tests**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotRecordingGeometryTests
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionRecordingTests
```

Expected: both pass.

### Task 3: Expose the Toolbar Recording Entry

**Files:**
- Modify: `MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift`
- Test: `MacShotCoreTests/MacShotToolbarPolicyTests.swift`

- [ ] **Step 1: Add a failing toolbar test**

In `MacShotCoreTests/MacShotToolbarPolicyTests.swift`, add:

```swift
func testRightToolbarExposesRecordActionOutsideEditorMode() {
    let buttons = ToolbarLayout.rightButtons(isEditorMode: false)

    XCTAssertTrue(buttons.contains { button in
        if case .record = button.action { return true }
        return false
    })
}

func testRightToolbarHidesRecordActionInEditorMode() {
    let buttons = ToolbarLayout.rightButtons(isEditorMode: true)

    XCTAssertFalse(buttons.contains { button in
        if case .record = button.action { return true }
        return false
    })
}
```

- [ ] **Step 2: Run the toolbar test to confirm failure**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotToolbarPolicyTests
```

Expected: `testRightToolbarExposesRecordActionOutsideEditorMode` fails while `recordingEnabled` is false.

- [ ] **Step 3: Enable recording flag**

In `MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift`, change:

```swift
static let recordingEnabled = false
```

to:

```swift
static let recordingEnabled = true
```

- [ ] **Step 4: Run the toolbar test**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotToolbarPolicyTests
```

Expected: toolbar policy tests pass.

### Task 4: Full Verification

**Files:**
- No source changes unless tests reveal defects.

- [ ] **Step 1: Regenerate project if new files are not in Xcode project**

Run:

```bash
make generate
```

Expected: XcodeGen updates `ScreenshotTool.xcodeproj/project.pbxproj` to include new files.

- [ ] **Step 2: Run full tests**

Run:

```bash
make test
```

Expected: all `ScreenshotToolTests` and `MacShotCoreTests` pass.

- [ ] **Step 3: Build and launch verification**

Run:

```bash
./script/build_and_run.sh --verify
```

Expected: build succeeds and `pgrep -x ScreenshotTool` succeeds.

- [ ] **Step 4: Manual smoke check**

In the app:

1. Start screenshot capture.
2. Drag a region.
3. Click the video/record toolbar button.
4. Click the red start-recording button.
5. Wait 2 seconds.
6. Stop recording from the recording flow.
7. Confirm an `.mp4` file appears on Desktop.

---

## Self-Review

- Spec coverage: covers visible toolbar entry, recording setup mode, selected-region recording, MP4 output, and session completion.
- Explicitly out of scope: audio, webcam, keystroke overlay, pause/resume, editor import for recordings, recording preferences UI.
- Placeholder scan: no TBD/TODO placeholders.
- Type consistency: tests and implementation use `MacShotRecordingEngine`, `ScreenCaptureKitRecordingEngine`, `RecordingCompletion`, and `MacShotCaptureResult.recordingURL` consistently.
