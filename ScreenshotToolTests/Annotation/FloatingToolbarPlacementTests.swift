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

    func testPlacementCentersToolbarOnSelectionWhenThereIsEnoughHorizontalSpace() {
        let placement = FloatingToolbarPlacement.resolve(
            selectionRect: CGRect(x: 360, y: 180, width: 180, height: 120),
            availableRect: CGRect(x: 0, y: 0, width: 900, height: 600),
            toolbarSize: CGSize(width: 320, height: 56)
        )

        XCTAssertEqual(placement.width, 320)
        XCTAssertGreaterThanOrEqual(placement.minX, 0)
        XCTAssertLessThanOrEqual(placement.maxX, 900)
        XCTAssertEqual(placement.midX, 360 + 90, accuracy: 0.5)
    }

    func testPlacementClampsToolbarInsideAvailableRectNearTrailingEdge() {
        let placement = FloatingToolbarPlacement.resolve(
            selectionRect: CGRect(x: 740, y: 180, width: 180, height: 120),
            availableRect: CGRect(x: 0, y: 0, width: 900, height: 600),
            toolbarSize: CGSize(width: 320, height: 56)
        )

        XCTAssertEqual(placement.maxX, 900, accuracy: 0.5)
    }
}
