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
    func testSetDefaultSaveDirectoryPersistsSelection() throws {
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
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ScreenshotToolCustom")

        viewModel.setDefaultSaveDirectory(directory)

        XCTAssertEqual(preferencesStore.capturePreferences.defaultSaveDirectoryPath, directory.path)
        XCTAssertEqual(viewModel.capturePreferences.defaultSaveDirectoryPath, directory.path)
    }

    @MainActor
    func testSetPlayCaptureSoundPersistsSelection() {
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

        viewModel.setPlayCaptureSound(true)

        XCTAssertTrue(preferencesStore.capturePreferences.playCaptureSound)
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

    @MainActor
    func testRefreshPermissionsPullsLatestSnapshot() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let permissionsService = FakePermissionsService()
        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: permissionsService,
            loginItemService: FakeLoginItemService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeSettingsInputSourceService(),
                matcher: InputMethodRuleMatcher()
            )
        )

        permissionsService.snapshot = PermissionsSnapshot(screenRecording: .granted, accessibility: .denied)
        viewModel.refreshPermissions()

        XCTAssertEqual(viewModel.permissionSnapshot.screenRecording, .granted)
        XCTAssertEqual(viewModel.permissionSnapshot.accessibility, .denied)
    }

    @MainActor
    func testOpenScreenRecordingSettingsRequestsAccessBeforeOpeningSettings() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let permissionsService = FakePermissionsService()
        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: permissionsService,
            loginItemService: FakeLoginItemService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeSettingsInputSourceService(),
                matcher: InputMethodRuleMatcher()
            )
        )

        viewModel.openScreenRecordingSettings()

        XCTAssertEqual(permissionsService.requestScreenRecordingAccessIfNeededCount, 1)
        XCTAssertEqual(permissionsService.openScreenRecordingSettingsCount, 1)
    }

    @MainActor
    func testSetMenuBarIconVisibleUpdatesControllerImmediately() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let menuBarController = FakeMenuBarController()
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
            ),
            menuBarController: menuBarController
        )

        viewModel.setMenuBarIconVisible(false)

        XCTAssertEqual(menuBarController.visibleValues, [false])
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

private final class FakePermissionsService: PermissionsService {
    var snapshot = PermissionsSnapshot(screenRecording: .unknown, accessibility: .unknown)
    var requestScreenRecordingAccessIfNeededCount = 0
    var openScreenRecordingSettingsCount = 0

    func currentSnapshot() -> PermissionsSnapshot {
        snapshot
    }

    func requestScreenRecordingAccessIfNeeded() -> Bool {
        requestScreenRecordingAccessIfNeededCount += 1
        return snapshot.screenRecording == .granted
    }

    func openScreenRecordingSettings() {
        openScreenRecordingSettingsCount += 1
    }
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

@MainActor
private final class FakeMenuBarController: MenuBarVisibilityControlling {
    var visibleValues: [Bool] = []

    func setVisible(_ visible: Bool) {
        visibleValues.append(visible)
    }
}
