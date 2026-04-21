import XCTest
@testable import ScreenshotTool

final class SettingsWindowViewModelTests: XCTestCase {
    @MainActor
    func testSetLaunchAtLoginPersistsAndCallsService() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let loginItemService = FakeLoginItemService()
        let permissionsService = FakePermissionsService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            matcher: InputMethodRuleMatcher()
        )

        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: permissionsService,
            loginItemService: loginItemService,
            inputMethodManager: manager
        )

        try viewModel.setLaunchAtLogin(true)

        XCTAssertTrue(preferencesStore.appPreferences.launchAtLogin)
        XCTAssertEqual(loginItemService.lastSetValue, true)
    }

    @MainActor
    func testSetThemePreferencePersistsSelection() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: FakePermissionsService(),
            loginItemService: FakeLoginItemService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeSettingsInputSourceService(),
                matcher: InputMethodRuleMatcher()
            )
        )

        viewModel.setThemePreference(.dark)

        XCTAssertEqual(preferencesStore.appPreferences.themePreference, .dark)
    }

    @MainActor
    func testSetImageFormatPersistsSelection() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: FakePermissionsService(),
            loginItemService: FakeLoginItemService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeSettingsInputSourceService(),
                matcher: InputMethodRuleMatcher()
            )
        )

        viewModel.setImageFormat(.jpeg)

        XCTAssertEqual(preferencesStore.capturePreferences.imageFormat, .jpeg)
    }

    @MainActor
    func testToggleRuleEnabledPersistsUpdatedRule() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        let initialRule = AppInputMethodRule(
            id: UUID(),
            bundleIdentifier: "com.apple.TextEdit",
            appName: "TextEdit",
            inputSourceID: "com.apple.keylayout.ABC",
            isEnabled: true
        )
        try rulesStore.upsert(initialRule)

        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: FakePermissionsService(),
            loginItemService: FakeLoginItemService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeSettingsInputSourceService(),
                matcher: InputMethodRuleMatcher()
            )
        )

        try viewModel.setRuleEnabled(id: initialRule.id, enabled: false)

        XCTAssertEqual(viewModel.rules.first?.isEnabled, false)
        XCTAssertEqual(InputMethodRulesStore(fileURL: rulesURL).rules.first?.isEnabled, false)
    }
}

private final class FakeLoginItemService: LoginItemService {
    var lastSetValue: Bool?

    func currentStatus() -> Bool {
        false
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        lastSetValue = enabled
    }
}

private struct FakePermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .unknown, accessibility: .unknown)
    }

    func openScreenRecordingSettings() {}
    func openAccessibilitySettings() {}
}

private final class FakeSettingsInputSourceService: InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor] {
        [InputSourceDescriptor(id: "com.apple.keylayout.ABC", localizedName: "ABC")]
    }

    func currentInputSourceID() -> String? {
        "com.apple.keylayout.ABC"
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        true
    }
}
