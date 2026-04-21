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
    let captureCoordinator: CaptureCoordinator
    let hotkeyHandler: CaptureHotkeyHandler
    let menuBarController: MenuBarController
    let historyStore: CaptureHistoryStore
    let outputService: CaptureOutputService
    let themeController: AppThemeController
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
        windowRouter: WindowRouter,
        captureCoordinator: CaptureCoordinator,
        hotkeyHandler: CaptureHotkeyHandler,
        menuBarController: MenuBarController,
        historyStore: CaptureHistoryStore,
        outputService: CaptureOutputService
    ) {
        self.windowTitle = windowTitle
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.permissionsService = permissionsService
        self.loginItemService = loginItemService
        self.inputSourceService = inputSourceService
        self.inputMethodManager = inputMethodManager
        self.windowRouter = windowRouter
        self.captureCoordinator = captureCoordinator
        self.hotkeyHandler = hotkeyHandler
        self.menuBarController = menuBarController
        self.historyStore = historyStore
        self.outputService = outputService
        self.themeController = AppThemeController(preferencesStore: preferencesStore)
        self.mainWindowViewModel = MainWindowViewModel(
            permissionsService: permissionsService,
            windowRouter: windowRouter,
            historyStore: historyStore,
            startCaptureAction: {
                captureCoordinator.beginCapture()
            }
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

    func start() {
        inputMethodManager.startObserving()
        try? hotkeyHandler.start()
        menuBarController.setVisible(preferencesStore.appPreferences.showsMenuBarIcon)
        captureCoordinator.onCaptureStarted = { [weak windowRouter, weak captureCoordinator] in
            guard let coordinator = captureCoordinator else { return }
            windowRouter?.showCaptureOverlay(
                onSelectionChanged: { start, end in
                    coordinator.updateSelection(start: start, end: end)
                },
                onSelectionCompleted: {
                    Task { @MainActor in
                        try? await coordinator.completeSelection()
                    }
                },
                onCancelled: {
                    coordinator.cancelCapture()
                }
            )
        }
        captureCoordinator.onCaptureCancelled = { [weak windowRouter] in
            windowRouter?.hideCaptureOverlay()
        }
        captureCoordinator.onCaptureCompleted = { [weak self, weak windowRouter] result in
            guard let self else { return }
            windowRouter?.hideCaptureOverlay()
            let document = AnnotationDocument()
            let defaultDirectory = URL(fileURLWithPath: self.preferencesStore.capturePreferences.defaultSaveDirectoryPath ?? FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("ScreenshotTool").path)
            windowRouter?.presentFloatingToolbar(
                for: result,
                document: document,
                outputService: self.outputService,
                defaultSaveDirectory: defaultDirectory,
                imageFormat: self.preferencesStore.capturePreferences.imageFormat
            )
            self.mainWindowViewModel.refresh()
        }
    }

    static func bootstrap() -> AppEnvironment {
        let preferencesStore = AppPreferencesStore()
        let rulesURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/input-method-rules.json")
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        let inputSourceService = TISInputSourceService()
        let windowRouter = WindowRouter()
        let captureCoordinator = CaptureCoordinator(screenCaptureService: WindowListScreenCaptureService())
        let historyURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/history.json")
        let historyStore = CaptureHistoryStore(fileURL: historyURL, limit: preferencesStore.annotationPreferences.historyLimit)
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher(),
            observer: WorkspaceFrontmostApplicationObserver()
        )
        let hotkeyHandler = CaptureHotkeyHandler(
            hotkeyService: CarbonHotkeyService(),
            preferencesStore: preferencesStore,
            captureCoordinator: captureCoordinator
        )
        let menuBarController = MenuBarController(
            openSettings: {
                windowRouter.openSettings()
            },
            startCapture: {
                captureCoordinator.beginCapture()
            }
        )
        let cacheDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/Captures")
        let outputService = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: PasteboardClipboardService(),
            historyStore: historyStore,
            cacheDirectory: cacheDirectory
        )

        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: windowRouter,
            captureCoordinator: captureCoordinator,
            hotkeyHandler: hotkeyHandler,
            menuBarController: menuBarController,
            historyStore: historyStore,
            outputService: outputService
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
        let windowRouter = WindowRouter()
        let captureCoordinator = CaptureCoordinator(screenCaptureService: WindowListScreenCaptureService())
        let historyStore = CaptureHistoryStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("history-tests.json"),
            limit: preferencesStore.annotationPreferences.historyLimit
        )
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )
        let hotkeyHandler = CaptureHotkeyHandler(
            hotkeyService: CarbonHotkeyService(),
            preferencesStore: preferencesStore,
            captureCoordinator: captureCoordinator
        )
        let menuBarController = MenuBarController(
            openSettings: {
                windowRouter.openSettings()
            },
            startCapture: {
                captureCoordinator.beginCapture()
            }
        )
        let outputService = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: PasteboardClipboardService(),
            historyStore: historyStore,
            cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("captures-tests")
        )

        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: windowRouter,
            captureCoordinator: captureCoordinator,
            hotkeyHandler: hotkeyHandler,
            menuBarController: menuBarController,
            historyStore: historyStore,
            outputService: outputService
        )
    }
}
