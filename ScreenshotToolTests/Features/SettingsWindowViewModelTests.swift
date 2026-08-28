import XCTest
@testable import ScreenshotTool

final class SettingsWindowViewModelTests: XCTestCase {
    @MainActor
    func testAppVersionDisplayNameUsesBundleShortVersionAndBuildNumber() {
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
            ),
            bundle: InfoPlistTestBundle(values: [
                "CFBundleShortVersionString": "0.1.1234",
                "CFBundleVersion": "1777771234"
            ])
        )

        XCTAssertEqual(viewModel.appVersionDisplayName, "0.1.1234")
    }

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
        XCTAssertTrue(viewModel.launchAtLoginStatus)
    }

    @MainActor
    func testSetGlobalInputSourceAppliesImmediatelyToFrontmostApplication() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        )
        let inputSourceService = FakeSettingsInputSourceService(current: "com.apple.inputmethod.SCIM.WBX")
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )
        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            permissionsService: FakePermissionsService(),
            loginItemService: FakeLoginItemService(),
            inputMethodManager: manager
        )

        viewModel.setInputMethodEnabled(true)
        viewModel.setGlobalInputSourceID("com.apple.keylayout.ABC")

        XCTAssertEqual(inputSourceService.selectedIDs, ["com.apple.keylayout.ABC"])
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
    func testSetCaptureHotkeyPersistsSelectionAndReloadsGlobalHotkey() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        var reloadCount = 0
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
            reloadCaptureHotkey: {
                reloadCount += 1
            }
        )
        let hotkey = GlobalHotkey(keyCode: 11, modifiers: [.command, .shift])

        try viewModel.setCaptureHotkey(hotkey)

        XCTAssertEqual(preferencesStore.capturePreferences.hotkey, hotkey)
        XCTAssertEqual(viewModel.capturePreferences.hotkey, hotkey)
        XCTAssertEqual(reloadCount, 1)
    }

    @MainActor
    func testSetCaptureHotkeyRejectsSystemReservedCommandShiftA() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        var reloadCount = 0
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
            reloadCaptureHotkey: {
                reloadCount += 1
            }
        )

        XCTAssertThrowsError(
            try viewModel.setCaptureHotkey(GlobalHotkey(keyCode: 0, modifiers: [.command, .shift]))
        )
        XCTAssertEqual(preferencesStore.capturePreferences.hotkey, .defaultCapture)
        XCTAssertEqual(reloadCount, 0)
        XCTAssertNotNil(viewModel.captureHotkeyErrorMessage)
    }

    @MainActor
    func testSetCaptureHotkeyRollsBackWhenGlobalReloadFails() throws {
        struct ReloadError: Error {}

        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let originalHotkey = preferencesStore.capturePreferences.hotkey
        var reloadCount = 0
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
            reloadCaptureHotkey: {
                reloadCount += 1
                throw ReloadError()
            }
        )

        XCTAssertThrowsError(try viewModel.setCaptureHotkey(GlobalHotkey(keyCode: 11, modifiers: [.command, .shift])))

        XCTAssertEqual(preferencesStore.capturePreferences.hotkey, originalHotkey)
        XCTAssertEqual(viewModel.capturePreferences.hotkey, originalHotkey)
        XCTAssertEqual(reloadCount, 2)
        XCTAssertNotNil(viewModel.captureHotkeyErrorMessage)
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
    var current: String
    private(set) var selectedIDs: [String] = []

    init(current: String = "com.apple.keylayout.ABC") {
        self.current = current
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        [InputSourceDescriptor(id: "com.apple.keylayout.ABC", localizedName: "ABC")]
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

@MainActor
private final class FakeMenuBarController: MenuBarVisibilityControlling {
    var visibleValues: [Bool] = []

    func setVisible(_ visible: Bool) {
        visibleValues.append(visible)
    }
}

private final class InfoPlistTestBundle: Bundle, @unchecked Sendable {
    private let values: [String: Any]

    init(values: [String: Any]) {
        self.values = values
        super.init()
    }

    override func object(forInfoDictionaryKey key: String) -> Any? {
        values[key]
    }
}
