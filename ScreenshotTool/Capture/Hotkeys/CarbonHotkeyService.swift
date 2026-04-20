import Carbon
import Foundation

final class CarbonHotkeyService: HotkeyService {
    private var handlers: [UInt32: () -> Void] = [:]
    private var hotKeyRefs: [EventHotKeyRef] = []

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        handlers[hotkey.keyCode] = handler
    }

    func unregisterAll() {
        handlers.removeAll()
        hotKeyRefs.removeAll()
    }
}
