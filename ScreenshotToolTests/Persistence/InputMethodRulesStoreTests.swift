import XCTest
@testable import ScreenshotTool

final class InputMethodRulesStoreTests: XCTestCase {
    func testUpsertPersistsRuleToDisk() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: fileURL)

        let store = InputMethodRulesStore(fileURL: fileURL)
        let rule = AppInputMethodRule(
            id: UUID(),
            bundleIdentifier: "com.apple.Terminal",
            appName: "Terminal",
            inputSourceID: "com.apple.keylayout.US",
            isEnabled: true
        )

        try store.upsert(rule)

        let reloaded = InputMethodRulesStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.rules, [rule])
    }
}
