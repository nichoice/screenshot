import XCTest
@testable import ScreenshotTool

final class CaptureHotkeyHandlerTests: XCTestCase {
    @MainActor
    func testStartRegistersConfiguredHotkey() throws {
        let hotkeyService = FakeHotkeyService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let handler = CaptureHotkeyHandler(
            hotkeyService: hotkeyService,
            preferencesStore: preferencesStore,
            startCapture: {}
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
