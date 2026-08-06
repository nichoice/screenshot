import XCTest
@testable import ScreenshotTool

final class ScreenshotToolSmokeTests: XCTestCase {
    @MainActor
    func testAppEnvironmentExposesExpectedTitle() {
        let environment = AppEnvironment.bootstrapForTests()
        XCTAssertEqual(environment.windowTitle, "SnapPii")
    }

    @MainActor
    func testThemeControllerReflectsPreferenceChangesWithoutRestart() {
        let environment = AppEnvironment.bootstrapForTests()

        environment.preferencesStore.updateApp { $0.themePreference = .dark }

        XCTAssertEqual(environment.themeController.preferredColorScheme, .dark)
    }

    @MainActor
    func testDefaultCaptureOutputActionUpdatesWithoutRestart() {
        let environment = AppEnvironment.bootstrapForTests()

        environment.preferencesStore.updateCapture { $0.defaultOutputAction = .saveOnly }

        XCTAssertEqual(environment.preferencesStore.capturePreferences.defaultOutputAction, .saveOnly)
    }
}
