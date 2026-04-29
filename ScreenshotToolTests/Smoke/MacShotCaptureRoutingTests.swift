import XCTest
@testable import MacShotCore
@testable import ScreenshotTool

@MainActor
final class MacShotCaptureRoutingTests: XCTestCase {
    func testStartCaptureUsesMacShotCoreEngine() {
        let environment = makeEnvironment()

        XCTAssertFalse(environment.macShotCaptureEngine.isCapturing)
        environment.startCapture()

        XCTAssertTrue(environment.macShotCaptureEngine.isCapturing)
    }
}

private extension MacShotCaptureRoutingTests {
    func makeEnvironment() -> AppEnvironment {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-rules.json")
        )
        let inputSourceService = RoutingInputSourceService()
        let inputMethodManager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )
        let historyStore = CaptureHistoryStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-history.json"),
            limit: 5
        )

        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: RoutingGrantedPermissionsService(),
            loginItemService: RoutingLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: inputMethodManager,
            windowRouter: WindowRouter(),
            captureCoordinator: CaptureCoordinator(screenCaptureService: RoutingScreenCaptureService()),
            hotkeyHandler: CaptureHotkeyHandler(
                hotkeyService: RoutingHotkeyService(),
                preferencesStore: preferencesStore,
                startCapture: {}
            ),
            menuBarController: MenuBarController(openSettings: {}, startCapture: {}),
            historyStore: historyStore,
            outputService: CaptureOutputService(
                renderer: AnnotationRenderer(),
                clipboardService: PasteboardClipboardService(),
                historyStore: historyStore,
                cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-captures")
            ),
            ocrService: VisionOCRService(),
            shareService: SystemShareService(),
            captureSoundPlayer: RoutingCaptureSoundPlayer(),
            macShotCaptureEngine: MacShotCaptureEngine(presentsOverlay: false)
        )
    }
}

private struct RoutingGrantedPermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .granted, accessibility: .granted)
    }

    func requestScreenRecordingAccessIfNeeded() -> Bool {
        true
    }

    func openScreenRecordingSettings() {}
    func openAccessibilitySettings() {}
}

private struct RoutingInputSourceService: InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor] { [] }
    func currentInputSourceID() -> String? { nil }
    @discardableResult func selectInputSource(id: String) -> Bool { true }
}

private struct RoutingLoginItemService: LoginItemService {
    func currentStatus() -> Bool { false }
    func setLaunchAtLogin(_ enabled: Bool) throws {}
}

private struct RoutingScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        fatalError("Not needed for this test")
    }
}

private final class RoutingHotkeyService: HotkeyService {
    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {}
    func unregisterAll() {}
}

@MainActor
private final class RoutingCaptureSoundPlayer: CaptureSoundPlaying {
    func playCaptureSound() {}
}
