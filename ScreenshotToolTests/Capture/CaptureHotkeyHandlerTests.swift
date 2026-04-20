import XCTest
@testable import ScreenshotTool

final class CaptureHotkeyHandlerTests: XCTestCase {
    @MainActor
    func testStartRegistersConfiguredHotkey() throws {
        let hotkeyService = FakeHotkeyService()
        let coordinator = CaptureCoordinator(screenCaptureService: FakeCoordinatorCaptureService())
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let handler = CaptureHotkeyHandler(
            hotkeyService: hotkeyService,
            preferencesStore: preferencesStore,
            captureCoordinator: coordinator
        )

        try handler.start()

        XCTAssertEqual(hotkeyService.registeredHotkey, .defaultCapture)
    }
}

private final class FakeHotkeyService: HotkeyService {
    var registeredHotkey: GlobalHotkey?

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        registeredHotkey = hotkey
    }

    func unregisterAll() {}
}

private struct FakeCoordinatorCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        fatalError("Not needed for this test")
    }
}
