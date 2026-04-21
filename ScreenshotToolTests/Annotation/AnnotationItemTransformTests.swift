import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class AnnotationItemTransformTests: XCTestCase {
    func testOffsettingRectangleTranslatesItsRect() {
        let item = AnnotationItem.rectangle(CGRect(x: 10, y: 20, width: 30, height: 40), "#FF0000", 2)

        XCTAssertEqual(item.offsetBy(dx: -5, dy: 8), .rectangle(CGRect(x: 5, y: 28, width: 30, height: 40), "#FF0000", 2))
    }

    func testOffsettingPenTranslatesAllPoints() {
        let item = AnnotationItem.pen([CGPoint(x: 1, y: 2), CGPoint(x: 3, y: 4)], "#00FF00", 3)

        XCTAssertEqual(
            item.offsetBy(dx: 10, dy: -2),
            .pen([CGPoint(x: 11, y: 0), CGPoint(x: 13, y: 2)], "#00FF00", 3)
        )
    }
}
