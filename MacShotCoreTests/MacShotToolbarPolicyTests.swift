import AppKit
import XCTest
@testable import MacShotCore

final class MacShotToolbarPolicyTests: XCTestCase {
    func testPhaseOneBottomToolbarDoesNotExposeUnsupportedActions() {
        let actions = ToolbarLayout.bottomButtons(
            selectedTool: .arrow,
            selectedColor: .systemRed,
            hasAnnotations: false
        ).map(\.action)

        XCTAssertFalse(actions.containsAction(.effects))
        XCTAssertFalse(actions.containsAction(.beautify))
    }

    func testPhaseOneRightToolbarDoesNotExposeUnsupportedActions() {
        let actions = ToolbarLayout.rightButtons().map(\.action)

        XCTAssertFalse(actions.containsAction(.record))
        XCTAssertFalse(actions.containsAction(.scrollCapture))
        XCTAssertFalse(actions.containsAction(.upload))
        XCTAssertFalse(actions.containsAction(.ocr))
        XCTAssertFalse(actions.containsAction(.translate))
    }
}

private extension [ToolbarButtonAction] {
    func containsAction(_ expected: ToolbarButtonAction) -> Bool {
        contains { action in
            switch (action, expected) {
            case (.effects, .effects),
                 (.beautify, .beautify),
                 (.record, .record),
                 (.scrollCapture, .scrollCapture),
                 (.upload, .upload),
                 (.ocr, .ocr),
                 (.translate, .translate):
                true
            default:
                false
            }
        }
    }
}
