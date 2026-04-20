import XCTest
@testable import ScreenshotTool

final class CaptureSelectionTests: XCTestCase {
    func testNormalizedRectUsesMinimumOriginAndAbsoluteSize() {
        let selection = CaptureSelection(start: CGPoint(x: 300, y: 400), end: CGPoint(x: 120, y: 220))

        XCTAssertEqual(selection.normalizedRect, CGRect(x: 120, y: 220, width: 180, height: 180))
    }
}
