import XCTest
@testable import ScreenshotTool

final class AppThemeControllerTests: XCTestCase {
    func testResolveExplicitDarkThemeReturnsDark() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.dark, systemIsDark: false), .dark)
    }

    func testResolveFollowSystemUsesSystemAppearance() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: true), .dark)
        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: false), .light)
    }
}
