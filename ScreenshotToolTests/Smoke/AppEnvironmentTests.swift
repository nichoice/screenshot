import XCTest
@testable import ScreenshotTool

final class AppEnvironmentTests: XCTestCase {
    @MainActor
    func testCaptureStartCancelsAndOpensSettingsWhenScreenRecordingAccessIsUnavailable() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-rules.json")
        )
        let permissionsService = FakeAppEnvironmentPermissionsService()
        let inputSourceService = FakeAppEnvironmentInputSourceService()
        let inputMethodManager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )
        let captureCoordinator = CaptureCoordinator(screenCaptureService: FakeAppEnvironmentScreenCaptureService())
        let hotkeyHandler = CaptureHotkeyHandler(
            hotkeyService: FakeAppEnvironmentHotkeyService(),
            preferencesStore: preferencesStore,
            captureCoordinator: captureCoordinator
        )
        let menuBarController = MenuBarController(openSettings: {}, startCapture: {})
        let historyStore = CaptureHistoryStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-history.json"),
            limit: 5
        )
        let environment = AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: permissionsService,
            loginItemService: FakeAppEnvironmentLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: inputMethodManager,
            windowRouter: WindowRouter(),
            captureCoordinator: captureCoordinator,
            hotkeyHandler: hotkeyHandler,
            menuBarController: menuBarController,
            historyStore: historyStore,
            outputService: CaptureOutputService(
                renderer: AnnotationRenderer(),
                clipboardService: PasteboardClipboardService(),
                historyStore: historyStore,
                cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-captures")
            ),
            ocrService: VisionOCRService(),
            shareService: SystemShareService(),
            captureSoundPlayer: FakeCaptureSoundPlayer()
        )

        environment.start()
        captureCoordinator.beginCapture()

        XCTAssertEqual(permissionsService.requestScreenRecordingAccessIfNeededCount, 1)
        XCTAssertEqual(permissionsService.openScreenRecordingSettingsCount, 1)
        XCTAssertFalse(captureCoordinator.isCapturing)
    }

    @MainActor
    func testCaptureCompletionPlaysSoundWhenPreferenceIsEnabled() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateCapture { $0.playCaptureSound = true }
        let rulesStore = InputMethodRulesStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-rules.json")
        )
        let historyStore = CaptureHistoryStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function)-history.json"),
            limit: 5
        )
        let soundPlayer = FakeCaptureSoundPlayer()
        let environment = AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: FakeGrantedAppEnvironmentPermissionsService(),
            loginItemService: FakeAppEnvironmentLoginItemService(),
            inputSourceService: FakeAppEnvironmentInputSourceService(),
            inputMethodManager: InputMethodManager(
                preferencesStore: preferencesStore,
                rulesStore: rulesStore,
                inputSourceService: FakeAppEnvironmentInputSourceService(),
                matcher: InputMethodRuleMatcher()
            ),
            windowRouter: WindowRouter(),
            captureCoordinator: CaptureCoordinator(screenCaptureService: FakeAppEnvironmentWorkingScreenCaptureService()),
            hotkeyHandler: CaptureHotkeyHandler(
                hotkeyService: FakeAppEnvironmentHotkeyService(),
                preferencesStore: preferencesStore,
                captureCoordinator: CaptureCoordinator(screenCaptureService: FakeAppEnvironmentWorkingScreenCaptureService())
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
            captureSoundPlayer: soundPlayer
        )

        environment.start()
        let result = CaptureResult(
            fullImage: makeTestImage(),
            image: makeTestImage(),
            selectionRect: CGRect(x: 10, y: 10, width: 40, height: 30),
            capturedAt: Date()
        )

        environment.captureCoordinator.onCaptureCompleted?(result)

        XCTAssertEqual(soundPlayer.playCount, 1)
    }
}

private final class FakeAppEnvironmentPermissionsService: PermissionsService {
    var requestScreenRecordingAccessIfNeededCount = 0
    var openScreenRecordingSettingsCount = 0

    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .denied, accessibility: .granted)
    }

    func requestScreenRecordingAccessIfNeeded() -> Bool {
        requestScreenRecordingAccessIfNeededCount += 1
        return false
    }

    func openScreenRecordingSettings() {
        openScreenRecordingSettingsCount += 1
    }

    func openAccessibilitySettings() {}
}

private struct FakeGrantedAppEnvironmentPermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .granted, accessibility: .granted)
    }

    func requestScreenRecordingAccessIfNeeded() -> Bool {
        true
    }

    func openScreenRecordingSettings() {}
    func openAccessibilitySettings() {}
}

private struct FakeAppEnvironmentInputSourceService: InputSourceService {
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

private struct FakeAppEnvironmentScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        XCTFail("Screen capture should not run when permission is unavailable")
        return CGImage(
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
            provider: CGDataProvider(data: Data(repeating: 255, count: 4) as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}

private struct FakeAppEnvironmentWorkingScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        makeTestImage()
    }
}

private final class FakeAppEnvironmentHotkeyService: HotkeyService {
    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {}
    func unregisterAll() {}
}

private struct FakeAppEnvironmentLoginItemService: LoginItemService {
    func currentStatus() -> Bool { false }
    func setLaunchAtLogin(_ enabled: Bool) throws {}
}

@MainActor
private final class FakeCaptureSoundPlayer: CaptureSoundPlaying {
    private(set) var playCount = 0

    func playCaptureSound() {
        playCount += 1
    }
}

private func makeTestImage() -> CGImage {
    CGImage(
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: CGDataProvider(data: Data(repeating: 255, count: 4) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
