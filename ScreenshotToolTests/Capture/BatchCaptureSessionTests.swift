import AppKit
import CoreGraphics
import XCTest
@testable import ScreenshotTool

@MainActor
final class BatchCaptureSessionTests: XCTestCase {
    func testAppendWritesOrderedPNGFiles() throws {
        let directory = temporaryDirectory()
        let session = BatchCaptureSession(rootDirectory: directory)
        defer { session.clearAllTemporaryFiles() }

        try session.begin()
        let first = try session.append(image: makeBatchImage(red: 255), capturedAt: Date(timeIntervalSince1970: 1))
        let second = try session.append(image: makeBatchImage(red: 128), capturedAt: Date(timeIntervalSince1970: 2))

        XCTAssertEqual(session.itemCount, 2)
        XCTAssertEqual(session.items.map(\.id), [first.id, second.id])
        XCTAssertEqual(first.fileURL.lastPathComponent, "capture-1.png")
        XCTAssertEqual(second.fileURL.lastPathComponent, "capture-2.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.fileURL.path))
    }

    func testRemoveDeletesOnlyTheSelectedTemporaryImage() throws {
        let directory = temporaryDirectory()
        let session = BatchCaptureSession(rootDirectory: directory)
        defer { session.clearAllTemporaryFiles() }

        try session.begin()
        let first = try session.append(image: makeBatchImage(red: 255), capturedAt: Date())
        let second = try session.append(image: makeBatchImage(red: 128), capturedAt: Date())

        session.remove(id: first.id)

        XCTAssertEqual(session.items.map(\.id), [second.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.fileURL.path))
    }

    func testStartingANewBatchRemovesThePreviousClipboardFiles() throws {
        let directory = temporaryDirectory()
        let session = BatchCaptureSession(rootDirectory: directory)
        defer { session.clearAllTemporaryFiles() }

        try session.begin()
        let first = try session.append(image: makeBatchImage(red: 255), capturedAt: Date())
        let completed = session.finish()

        XCTAssertEqual(completed.map(\.id), [first.id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.fileURL.path))

        try session.begin()

        XCTAssertFalse(FileManager.default.fileExists(atPath: first.fileURL.path))
        XCTAssertTrue(session.isActive)
        XCTAssertTrue(session.items.isEmpty)
    }

    func testClipboardWriterPublishesEachImageAsPNGAndFileURL() throws {
        let directory = temporaryDirectory()
        let session = BatchCaptureSession(rootDirectory: directory)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SnapPiiBatchCaptureTests-\(UUID().uuidString)"))
        defer {
            session.clearAllTemporaryFiles()
            pasteboard.clearContents()
        }

        try session.begin()
        let first = try session.append(image: makeBatchImage(red: 255), capturedAt: Date())
        let second = try session.append(image: makeBatchImage(red: 128), capturedAt: Date())

        let writer = PasteboardBatchClipboardService(pasteboard: pasteboard)

        XCTAssertTrue(writer.copy(items: [first, second]))
        let pastedItems = pasteboard.pasteboardItems ?? []
        XCTAssertEqual(pastedItems.count, 2)
        XCTAssertNotNil(pastedItems[0].data(forType: .png))
        XCTAssertNotNil(pastedItems[1].data(forType: .png))
        XCTAssertEqual(pastedItems[0].string(forType: .fileURL), first.fileURL.absoluteString)
        XCTAssertEqual(pastedItems[1].string(forType: .fileURL), second.fileURL.absoluteString)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}

private func makeBatchImage(red: UInt8) -> CGImage {
    let bytes = Data([red, 128, 64, 255])
    return CGImage(
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        ),
        provider: CGDataProvider(data: bytes as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
