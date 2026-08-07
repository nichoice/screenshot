import CoreGraphics
import ImageIO
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

        let image = makeImage()
        let result = CaptureResult(
            fullImage: image,
            image: image,
            selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2),
            capturedAt: Date()
        )
        let item = try service.save(
            result: result,
            document: AnnotationDocument(),
            format: .png,
            directory: directory
        )

        XCTAssertNotNil(item.savedFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath!))
        XCTAssertFalse(item.previewFilePath.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.previewFilePath))
        let sourceURL = URL(fileURLWithPath: item.savedFilePath!) as CFURL
        guard let source = CGImageSourceCreateWithURL(sourceURL, nil) else {
            XCTFail("Expected an encoded PNG image source")
            return
        }
        XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.png")
        XCTAssertEqual(clipboard.copyCount, 0)
    }

    func testCopyOnlyCopiesToClipboardWithoutWritingFilesOrHistory() throws {
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

        let image = makeImage()
        let result = CaptureResult(
            fullImage: image,
            image: image,
            selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2),
            capturedAt: Date()
        )
        service.copy(result: result, document: AnnotationDocument())

        XCTAssertEqual(clipboard.copyCount, 1)
        XCTAssertTrue(historyStore.items.isEmpty)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testPrepareShareItemWritesShareFileAndHistoryItem() throws {
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

        let image = makeImage()
        let result = CaptureResult(
            fullImage: image,
            image: image,
            selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2),
            capturedAt: Date()
        )
        let item = try service.prepareShareItem(
            result: result,
            document: AnnotationDocument(),
            format: .png,
            directory: directory
        )

        XCTAssertEqual(clipboard.copyCount, 0)
        XCTAssertNotNil(item.savedFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath!))
        XCTAssertEqual(historyStore.items.first?.id, item.id)
    }

    func testCopyRenderedImageOnlyWritesClipboard() throws {
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

        service.copyRenderedImage(makeImage())

        XCTAssertEqual(clipboard.copyCount, 1)
        XCTAssertTrue(historyStore.items.isEmpty)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testJPEGSaveUsesImageIODirectly() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(#function)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let historyStore = CaptureHistoryStore(fileURL: directory.appendingPathComponent("history.json"), limit: 10)
        let service = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: FakeClipboardService(),
            historyStore: historyStore,
            cacheDirectory: directory
        )

        let item = try service.saveRenderedImage(
            makeImage(),
            capturedAt: Date(timeIntervalSince1970: 123),
            format: .jpeg,
            directory: directory
        )

        let sourceURL = URL(fileURLWithPath: item.savedFilePath!) as CFURL
        guard let source = CGImageSourceCreateWithURL(sourceURL, nil) else {
            XCTFail("Expected an encoded JPEG image source")
            return
        }
        XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.jpeg")
    }

    func testSaveRenderedImageWritesFileAndHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(#function)
        let saveDirectory = directory.appendingPathComponent("saved")
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

        let item = try service.saveRenderedImage(
            makeImage(),
            capturedAt: Date(timeIntervalSince1970: 123),
            format: .png,
            directory: saveDirectory
        )

        XCTAssertNotNil(item.savedFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath!))
        XCTAssertEqual(clipboard.copyCount, 0)
        XCTAssertEqual(historyStore.items.first?.id, item.id)
    }

    func testCopyRecognizedTextWritesStringToClipboard() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(#function)
        let historyStore = CaptureHistoryStore(fileURL: directory.appendingPathComponent("history.json"), limit: 10)
        let clipboard = FakeClipboardService()
        let service = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: clipboard,
            historyStore: historyStore,
            cacheDirectory: directory
        )

        service.copyRecognizedText("识别结果")

        XCTAssertEqual(clipboard.lastCopiedText, "识别结果")
        XCTAssertEqual(clipboard.copyCount, 0)
    }
}

private final class FakeClipboardService: ClipboardService {
    var copyCount = 0
    var lastCopiedText: String?

    func copy(image: CGImage) {
        copyCount += 1
    }

    func copy(text: String) {
        lastCopiedText = text
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
