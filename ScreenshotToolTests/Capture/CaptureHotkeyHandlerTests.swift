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

    @MainActor
    func testStartRegistersCommandShiftAWhenConfigured() throws {
        let hotkeyService = FakeHotkeyService()
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateCapture {
            $0.hotkey = GlobalHotkey(keyCode: 0, modifiers: [.command, .shift])
        }
        let handler = CaptureHotkeyHandler(
            hotkeyService: hotkeyService,
            preferencesStore: preferencesStore,
            startCapture: {}
        )

        try handler.start()

        XCTAssertEqual(
            hotkeyService.registeredHotkey,
            GlobalHotkey(keyCode: 0, modifiers: [.command, .shift])
        )
    }
}

private final class FakeHotkeyService: HotkeyService {
    var registeredHotkey: GlobalHotkey?

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        registeredHotkey = hotkey
    }

    func unregisterAll() {}
}
