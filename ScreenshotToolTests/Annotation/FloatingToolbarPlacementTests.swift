import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class FloatingToolbarPlacementTests: XCTestCase {
    func testPlacementFlipsAboveSelectionWhenBottomSpaceIsInsufficient() {
        let placement = FloatingToolbarPlacement.resolve(
            selectionRect: CGRect(x: 100, y: 10, width: 160, height: 80),
            availableRect: CGRect(x: 0, y: 0, width: 400, height: 300),
            toolbarSize: CGSize(width: 220, height: 44)
        )

        XCTAssertLessThan(placement.origin.y, 100)
    }
}
