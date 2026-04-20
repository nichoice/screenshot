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
