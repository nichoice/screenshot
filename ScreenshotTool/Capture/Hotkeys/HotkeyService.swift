import Foundation

protocol HotkeyService {
    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws
    func unregisterAll()
}
