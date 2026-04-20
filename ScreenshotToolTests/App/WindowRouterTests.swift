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
}
