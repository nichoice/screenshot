import XCTest
@testable import ScreenshotTool

final class InputMethodRuleMatcherTests: XCTestCase {
    func testResolvePrefersEnabledAppRuleOverGlobalDefault() {
        let matcher = InputMethodRuleMatcher()
        let preferences = InputMethodPreferences(isEnabled: true, globalDefaultInputSourceID: "com.apple.keylayout.ABC")
        let rules = [
            AppInputMethodRule(
                id: UUID(),
                bundleIdentifier: "com.apple.Terminal",
                appName: "Terminal",
                inputSourceID: "com.apple.keylayout.US",
                isEnabled: true
            )
        ]

        let resolution = matcher.resolve(
            bundleIdentifier: "com.apple.Terminal",
            preferences: preferences,
            rules: rules
        )

        XCTAssertEqual(resolution.targetInputSourceID, "com.apple.keylayout.US")
        XCTAssertEqual(resolution.source, .appRule)
    }

    func testResolveFallsBackToGlobalDefaultWhenNoRuleMatches() {
        let matcher = InputMethodRuleMatcher()
        let preferences = InputMethodPreferences(isEnabled: true, globalDefaultInputSourceID: "com.apple.keylayout.ABC")

        let resolution = matcher.resolve(
            bundleIdentifier: "com.apple.TextEdit",
            preferences: preferences,
            rules: []
        )

        XCTAssertEqual(resolution.targetInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(resolution.source, .globalDefault)
    }
}
