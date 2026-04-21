import XCTest
@testable import ScreenshotTool

final class InlineAnnotationToolbarModelTests: XCTestCase {
    func testDefaultItemsMatchScreenshotEditingToolbarContract() {
        XCTAssertEqual(
            InlineAnnotationToolbarModel.defaultItems,
            [
                .rectangle,
                .ellipse,
                .emoji,
                .arrow,
                .pen,
                .mosaic,
                .text,
                .ocr,
                .undo,
                .save,
                .pin,
                .edit,
                .share,
                .cancel,
                .confirm
            ]
        )
    }

    func testToolbarGroupsMatchDenseCaptureEditingLayout() {
        XCTAssertEqual(
            InlineAnnotationToolbarModel.groups,
            [
                [.rectangle, .ellipse, .emoji, .arrow, .pen, .mosaic, .text, .ocr],
                [.undo],
                [.save, .pin, .edit, .share],
                [.cancel, .confirm]
            ]
        )
    }
}
