import XCTest
@testable import ScreenshotTool

final class AnnotationDocumentTests: XCTestCase {
    func testUndoRemovesLastAnnotationItem() {
        let document = AnnotationDocument()
        document.add(.rectangle(CGRect(x: 10, y: 10, width: 40, height: 30), "#FF3B30", 4))
        document.add(.text("Hello", CGPoint(x: 20, y: 20), "#111111", 14))

        document.undo()

        XCTAssertEqual(document.items.count, 1)
    }
}
