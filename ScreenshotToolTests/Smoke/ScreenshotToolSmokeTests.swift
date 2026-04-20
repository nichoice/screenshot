import XCTest
@testable import ScreenshotTool

final class ScreenshotToolSmokeTests: XCTestCase {
    @MainActor
    func testAppEnvironmentExposesExpectedTitle() {
        let environment = AppEnvironment.bootstrapForTests()
        XCTAssertEqual(environment.windowTitle, "Screenshot Tool")
    }
}
