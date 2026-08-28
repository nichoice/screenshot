import AppKit
import Foundation
import MacShotCore

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
    let ocrService: OCRService
    let shareService: ShareService
    let captureSoundPlayer: CaptureSoundPlaying
    let macShotCaptureEngine: MacShotCaptureEngine
    let batchCaptureSession: BatchCaptureSession
    let themeController: AppThemeController
    let mainWindowViewModel: MainWindowViewModel
    let settingsWindowViewModel: SettingsWindowViewModel
    private let batchClipboardService: BatchClipboardService
    private let batchCaptureTrayController: BatchCaptureTrayController

    init(
        windowTitle: String = "SnapPii",
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
        outputService: CaptureOutputService,
        ocrService: OCRService,
        shareService: ShareService,
        captureSoundPlayer: CaptureSoundPlaying,
        macShotCaptureEngine: MacShotCaptureEngine? = nil,
        batchCaptureSession: BatchCaptureSession? = nil,
        batchClipboardService: BatchClipboardService = PasteboardBatchClipboardService(),
        batchCaptureTrayController: BatchCaptureTrayController? = nil
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
        self.ocrService = ocrService
        self.shareService = shareService
        self.captureSoundPlayer = captureSoundPlayer
        self.macShotCaptureEngine = macShotCaptureEngine ?? MacShotCaptureEngine()
        self.batchCaptureSession = batchCaptureSession ?? BatchCaptureSession(
            rootDirectory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ScreenshotTool/BatchClipboard", isDirectory: true)
        )
        self.batchClipboardService = batchClipboardService
        self.batchCaptureTrayController = batchCaptureTrayController ?? BatchCaptureTrayController()
        self.themeController = AppThemeController(preferencesStore: preferencesStore)
        self.mainWindowViewModel = MainWindowViewModel(
            preferencesStore: preferencesStore,
            permissionsService: permissionsService,
            windowRouter: windowRouter,
            historyStore: historyStore,
            startCaptureAction: {}
        )
        self.settingsWindowViewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            permissionsService: permissionsService,
            loginItemService: loginItemService,
            inputMethodManager: inputMethodManager,
            menuBarController: menuBarController,
            reloadCaptureHotkey: {
                try hotkeyHandler.reload()
            }
        )
        self.mainWindowViewModel.replaceStartCaptureAction { [weak self] in
            self?.startCapture()
        }
        self.hotkeyHandler.replaceStartCaptureAction { [weak self] in
            self?.startCapture()
        }
        self.menuBarController.replaceStartCaptureAction { [weak self] in
            self?.startCapture()
        }
        self.menuBarController.replaceStartBatchCaptureAction { [weak self] in
            self?.startBatchCapture()
        }
    }

    func startCapture() {
        if batchCaptureSession.isActive {
            continueBatchCapture()
            return
        }

        beginCapture(onComplete: { [weak self] result in
            self?.handleMacShotCaptureResult(result)
        })
    }

    func startBatchCapture() {
        guard !batchCaptureSession.isActive else {
            continueBatchCapture()
            return
        }

        do {
            try batchCaptureSession.begin()
        } catch {
            return
        }
        continueBatchCapture()
    }

    private func continueBatchCapture() {
        guard batchCaptureSession.isActive, !macShotCaptureEngine.isCapturing else { return }
        batchCaptureTrayController.hide()
        beginCapture(
            onComplete: { [weak self] result in
                self?.handleBatchCaptureResult(result)
            },
            onCancel: { [weak self] in
                self?.showBatchCaptureTrayOrCancel()
            }
        )
    }

    private func beginCapture(
        onComplete: @escaping (MacShotCaptureResult) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        guard permissionsService.requestScreenRecordingAccessIfNeeded() else {
            permissionsService.openScreenRecordingSettings()
            return
        }

        macShotCaptureEngine.prepareForCapture()
        _ = macShotCaptureEngine.startCapture(
            preferences: macShotPreferences,
            onComplete: onComplete,
            onCancel: onCancel
        )
    }

    private func handleBatchCaptureResult(_ result: MacShotCaptureResult) {
        guard
            let image = result.image,
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            showBatchCaptureTrayOrCancel()
            return
        }

        if (try? batchCaptureSession.append(image: cgImage, capturedAt: result.capturedAt)) != nil,
           preferencesStore.capturePreferences.playCaptureSound {
            captureSoundPlayer.playCaptureSound()
        }
        showBatchCaptureTrayOrCancel()
    }

    private func showBatchCaptureTrayOrCancel() {
        guard batchCaptureSession.isActive else { return }
        guard batchCaptureSession.itemCount > 0 else {
            cancelBatchCapture()
            return
        }

        batchCaptureTrayController.show(
            items: batchCaptureSession.items,
            maximumItemCount: 20,
            onContinue: { [weak self] in
                self?.continueBatchCapture()
            },
            onCopyAll: { [weak self] in
                self?.copyBatchCaptureItems()
            },
            onCancel: { [weak self] in
                self?.cancelBatchCapture()
            },
            onRemove: { [weak self] itemID in
                self?.removeBatchCaptureItem(itemID)
            }
        )
    }

    private func removeBatchCaptureItem(_ itemID: UUID) {
        batchCaptureSession.remove(id: itemID)
        showBatchCaptureTrayOrCancel()
    }

    private func copyBatchCaptureItems() {
        let items = batchCaptureSession.finish()
        guard batchClipboardService.copy(items: items) else {
            batchCaptureSession.clearAllTemporaryFiles()
            batchCaptureTrayController.hide()
            return
        }
        batchCaptureTrayController.hide()
    }

    private func cancelBatchCapture() {
        batchCaptureSession.cancel()
        batchCaptureTrayController.hide()
    }

    func handleMacShotCaptureResult(_ result: MacShotCaptureResult) {
        if let recordingURL = result.recordingURL {
            NSWorkspace.shared.activateFileViewerSelecting([recordingURL])
            mainWindowViewModel.refresh()
            return
        }

        guard
            let image = result.image,
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return }

        let defaultDirectory = defaultCaptureDirectory()
        let preferences = preferencesStore.capturePreferences

        switch preferences.defaultOutputAction {
        case .copyOnly:
            outputService.copyRenderedImage(cgImage)
        case .saveOnly:
            _ = try? outputService.saveRenderedImage(
                cgImage,
                capturedAt: result.capturedAt,
                format: preferences.imageFormat,
                directory: defaultDirectory
            )
        case .copyAndSave:
            _ = try? outputService.saveRenderedImage(
                cgImage,
                capturedAt: result.capturedAt,
                format: preferences.imageFormat,
                directory: defaultDirectory
            )
            outputService.copyRenderedImage(cgImage)
        case .openEditor:
            let captureResult = CaptureResult(
                fullImage: cgImage,
                image: cgImage,
                selectionRect: CGRect(
                    origin: .zero,
                    size: CGSize(width: cgImage.width, height: cgImage.height)
                ),
                capturedAt: result.capturedAt
            )
            windowRouter.presentFloatingToolbar(
                for: captureResult,
                document: AnnotationDocument(),
                outputService: outputService,
                ocrService: ocrService,
                shareService: shareService,
                defaultSaveDirectory: defaultDirectory,
                imageFormat: preferences.imageFormat,
                defaultOutputAction: .openEditor
            )
        }

        if preferences.playCaptureSound {
            captureSoundPlayer.playCaptureSound()
        }
        mainWindowViewModel.refresh()
    }

    func start() {
        if permissionsService.currentSnapshot().screenRecording == .granted {
            macShotCaptureEngine.prepareForCapture()
        }

        let shouldLaunchAtLogin = preferencesStore.appPreferences.launchAtLogin
        if loginItemService.currentStatus() != shouldLaunchAtLogin {
            try? loginItemService.setLaunchAtLogin(shouldLaunchAtLogin)
        }
        settingsWindowViewModel.refreshLaunchAtLoginStatus()

        inputMethodManager.startObserving()
        startCaptureHotkeyWithRecovery()
        menuBarController.setVisible(preferencesStore.appPreferences.showsMenuBarIcon)
    }

    private func startCaptureHotkeyWithRecovery() {
        do {
            try hotkeyHandler.start()
        } catch {
            guard preferencesStore.capturePreferences.hotkey != .defaultCapture else {
                settingsWindowViewModel.reportDefaultCaptureHotkeyRegistrationFailure()
                return
            }

            settingsWindowViewModel.resetCaptureHotkeyAfterRegistrationFailure()
            do {
                try hotkeyHandler.start()
            } catch {
                settingsWindowViewModel.reportDefaultCaptureHotkeyRegistrationFailure()
            }
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
            startCapture: {}
        )
        let menuBarController = MenuBarController(
            openSettings: {
                windowRouter.openSettings()
            },
            startCapture: {}
        )
        let cacheDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/Captures")
        let outputService = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: PasteboardClipboardService(),
            historyStore: historyStore,
            cacheDirectory: cacheDirectory
        )
        let batchCaptureSession = BatchCaptureSession(
            rootDirectory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ScreenshotTool/BatchClipboard", isDirectory: true)
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
            outputService: outputService,
            ocrService: VisionOCRService(),
            shareService: SystemShareService(),
            captureSoundPlayer: SystemCaptureSoundPlayer(),
            batchCaptureSession: batchCaptureSession
        )
    }

    static func bootstrapForTests() -> AppEnvironment {
        let defaults = UserDefaults(suiteName: "ScreenshotToolTests")!
        defaults.removePersistentDomain(forName: "ScreenshotToolTests")
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenshotToolTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.removeItem(at: testDirectory)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(
            fileURL: testDirectory.appendingPathComponent("rules.json")
        )
        let inputSourceService = TISInputSourceService()
        let windowRouter = WindowRouter()
        let captureCoordinator = CaptureCoordinator(screenCaptureService: WindowListScreenCaptureService())
        let historyStore = CaptureHistoryStore(
            fileURL: testDirectory.appendingPathComponent("history.json"),
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
            startCapture: {}
        )
        let menuBarController = MenuBarController(
            openSettings: {
                windowRouter.openSettings()
            },
            startCapture: {}
        )
        let outputService = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: PasteboardClipboardService(),
            historyStore: historyStore,
            cacheDirectory: testDirectory.appendingPathComponent("captures", isDirectory: true)
        )
        let batchCaptureSession = BatchCaptureSession(
            rootDirectory: testDirectory.appendingPathComponent("batch-clipboard", isDirectory: true)
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
            outputService: outputService,
            ocrService: VisionOCRService(),
            shareService: SystemShareService(),
            captureSoundPlayer: SystemCaptureSoundPlayer(),
            batchCaptureSession: batchCaptureSession
        )
    }
}

private extension AppEnvironment {
    func defaultCaptureDirectory() -> URL {
        URL(
            fileURLWithPath: preferencesStore.capturePreferences.defaultSaveDirectoryPath
                ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
        )
    }

    var macShotPreferences: MacShotPreferences {
        MacShotPreferences(
            defaultColorHex: preferencesStore.annotationPreferences.defaultColorHex,
            defaultLineWidth: preferencesStore.annotationPreferences.defaultLineWidth,
            defaultFontSize: preferencesStore.annotationPreferences.defaultFontSize,
            rememberLastTool: preferencesStore.annotationPreferences.rememberLastTool,
            includeCursor: preferencesStore.capturePreferences.includeCursor,
            defaultSaveDirectoryPath: defaultCaptureDirectory().path
        )
    }
}

#if DEBUG
extension AppEnvironment {
    func handleMacShotCaptureResultForTesting(image: NSImage, capturedAt: Date) {
        handleMacShotCaptureResult(MacShotCaptureResult(image: image, capturedAt: capturedAt))
    }
}
#endif
