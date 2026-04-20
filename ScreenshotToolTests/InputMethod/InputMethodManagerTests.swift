import XCTest
@testable import ScreenshotTool

final class InputMethodManagerTests: XCTestCase {
    @MainActor
    func testHandleFrontmostApplicationChangeAppliesMatchingRule() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateInputMethod {
            $0.isEnabled = true
            $0.globalDefaultInputSourceID = "com.apple.keylayout.ABC"
        }

        let rulesURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: rulesURL)
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        try rulesStore.upsert(
            AppInputMethodRule(
                id: UUID(),
                bundleIdentifier: "com.apple.Terminal",
                appName: "Terminal",
                inputSourceID: "com.apple.keylayout.US",
                isEnabled: true
            )
        )

        let service = FakeInputSourceService(current: "com.apple.keylayout.ABC")
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: service,
            matcher: InputMethodRuleMatcher()
        )

        manager.handleFrontmostApplicationChange(bundleIdentifier: "com.apple.Terminal")

        XCTAssertEqual(service.selectedIDs, ["com.apple.keylayout.US"])
        XCTAssertEqual(manager.status.lastTargetInputSourceID, "com.apple.keylayout.US")
        XCTAssertEqual(manager.status.lastSwitchSucceeded, true)
    }
}

private final class FakeInputSourceService: InputSourceService {
    var current: String?
    var selectedIDs: [String] = []

    init(current: String?) {
        self.current = current
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        []
    }

    func currentInputSourceID() -> String? {
        current
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        selectedIDs.append(id)
        current = id
        return true
    }
}
