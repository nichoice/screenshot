import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String
    let preferencesStore: AppPreferencesStore
    let rulesStore: InputMethodRulesStore
    let permissionsService: PermissionsService
    let loginItemService: LoginItemService
    let inputSourceService: InputSourceService
    let inputMethodManager: InputMethodManager
    let windowRouter: WindowRouter
    let mainWindowViewModel: MainWindowViewModel
    let settingsWindowViewModel: SettingsWindowViewModel

    init(
        windowTitle: String = "Screenshot Tool",
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        permissionsService: PermissionsService,
        loginItemService: LoginItemService,
        inputSourceService: InputSourceService,
        inputMethodManager: InputMethodManager,
        windowRouter: WindowRouter
    ) {
        self.windowTitle = windowTitle
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.permissionsService = permissionsService
        self.loginItemService = loginItemService
        self.inputSourceService = inputSourceService
        self.inputMethodManager = inputMethodManager
        self.windowRouter = windowRouter
        self.mainWindowViewModel = MainWindowViewModel(
            permissionsService: permissionsService,
            windowRouter: windowRouter
        )
        self.settingsWindowViewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            permissionsService: permissionsService,
            loginItemService: loginItemService,
            inputMethodManager: inputMethodManager
        )
    }

    static func bootstrap() -> AppEnvironment {
        let preferencesStore = AppPreferencesStore()
        let rulesURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/input-method-rules.json")
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        let inputSourceService = TISInputSourceService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )

        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: WindowRouter()
        )
    }

    static func bootstrapForTests() -> AppEnvironment {
        let defaults = UserDefaults(suiteName: "ScreenshotToolTests")!
        defaults.removePersistentDomain(forName: "ScreenshotToolTests")
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("rules-tests.json")
        )
        let inputSourceService = TISInputSourceService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )

        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: WindowRouter()
        )
    }
}
