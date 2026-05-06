import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotRecordingGeometryTests: XCTestCase {
    func testSourceRectConvertsAppKitScreenRectToScreenCaptureKitRect() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let rect = NSRect(x: 100, y: 120, width: 640, height: 360)

        let sourceRect = ScreenCaptureKitRecordingEngine.sourceRect(for: rect, in: screenFrame)

        XCTAssertEqual(sourceRect.origin.x, 100)
        XCTAssertEqual(sourceRect.origin.y, 420)
        XCTAssertEqual(sourceRect.width, 640)
        XCTAssertEqual(sourceRect.height, 360)
    }
}
