import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureOutputServiceTests: XCTestCase {
    func testSaveWritesRenderedImageToConfiguredDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(#function)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let historyStore = CaptureHistoryStore(fileURL: directory.appendingPathComponent("history.json"), limit: 10)
        let clipboard = FakeClipboardService()
        let service = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: clipboard,
            historyStore: historyStore,
            cacheDirectory: directory
        )

        let result = CaptureResult(image: makeImage(), selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2), capturedAt: Date())
        let item = try service.save(
            result: result,
            document: AnnotationDocument(),
            format: .png,
            directory: directory
        )

        XCTAssertNotNil(item.savedFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath!))
        XCTAssertEqual(clipboard.copyCount, 0)
    }
}

private final class FakeClipboardService: ClipboardService {
    var copyCount = 0

    func copy(image: CGImage) {
        copyCount += 1
    }
}

private func makeImage() -> CGImage {
    CGImage(
        width: 2,
        height: 2,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: CGDataProvider(data: Data(repeating: 255, count: 16) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
