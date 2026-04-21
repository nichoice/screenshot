import XCTest
@testable import ScreenshotTool

final class WindowRouterTests: XCTestCase {
    @MainActor
    func testOpenSettingsUsesConfiguredHandler() {
        let router = WindowRouter()
        var wasCalled = false

        router.configureOpenSettings {
            wasCalled = true
        }

        router.openSettings()

        XCTAssertTrue(wasCalled)
    }

    @MainActor
    func testInlineCaptureToolbarPlacementPrefersBottomWhenSpaceIsAvailable() {
        let placement = FloatingToolbarPlacement.resolve(
            selectionRect: CGRect(x: 120, y: 120, width: 360, height: 220),
            availableRect: CGRect(x: 0, y: 0, width: 1200, height: 900),
            toolbarSize: CGSize(width: 640, height: 56)
        )

        XCTAssertGreaterThan(placement.minY, 340)
    }
}
