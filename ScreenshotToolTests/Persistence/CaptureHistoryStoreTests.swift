import XCTest
@testable import ScreenshotTool

final class CaptureHistoryStoreTests: XCTestCase {
    func testAppendTrimsItemsToConfiguredLimit() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: fileURL)
        let store = CaptureHistoryStore(fileURL: fileURL, limit: 2)

        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "a.png", savedFilePath: nil, didCopyToClipboard: true))
        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "b.png", savedFilePath: nil, didCopyToClipboard: true))
        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "c.png", savedFilePath: nil, didCopyToClipboard: true))

        XCTAssertEqual(store.items.count, 2)
    }
}
