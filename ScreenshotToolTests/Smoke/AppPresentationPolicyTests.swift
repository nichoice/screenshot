import AppKit
import XCTest
@testable import ScreenshotTool

final class AppPresentationPolicyTests: XCTestCase {
    func testBackgroundResidentActivationPolicyHidesDockIcon() {
        XCTAssertEqual(AppPresentationPolicy.backgroundResidentActivationPolicy, .accessory)
    }

    func testClosingLastWindowKeepsBackgroundResidentAppRunning() {
        XCTAssertFalse(AppPresentationPolicy.shouldTerminateAfterLastWindowClosed)
    }
}
