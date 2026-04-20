import Carbon
import Foundation

private let carbonHotkeyEventHandler: EventHandlerUPP = { _, eventRef, _ in
    guard let eventRef else { return noErr }
    return CarbonHotkeyService.handleHotKeyEvent(eventRef)
}

final class CarbonHotkeyService: HotkeyService {
    private enum Constants {
        static let signature: OSType = 0x53484F54
    }

    private static var installedHandlerRef: EventHandlerRef?
    private static var handlers: [UInt32: () -> Void] = [:]

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var registeredIDs: [UInt32] = []

    init() {
        Self.installEventHandlerIfNeeded()
    }

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        Self.handlers[hotkey.keyCode] = handler

        var hotKeyID = EventHotKeyID(signature: Constants.signature, id: hotkey.keyCode)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            Self.carbonModifiers(for: hotkey.modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            throw NSError(domain: "CarbonHotkeyService", code: Int(status))
        }

        hotKeyRefs.append(hotKeyRef)
        registeredIDs.append(hotkey.keyCode)
    }

    func unregisterAll() {
        hotKeyRefs.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        registeredIDs.forEach { Self.handlers.removeValue(forKey: $0) }
        registeredIDs.removeAll()
    }

    static func carbonModifiers(for modifiers: [HotkeyModifier]) -> UInt32 {
        modifiers.reduce(0) { partial, modifier in
            partial | carbonModifier(for: modifier)
        }
    }

    private static func carbonModifier(for modifier: HotkeyModifier) -> UInt32 {
        switch modifier {
        case .command:
            return UInt32(cmdKey)
        case .option:
            return UInt32(optionKey)
        case .control:
            return UInt32(controlKey)
        case .shift:
            return UInt32(shiftKey)
        }
    }

    private static func installEventHandlerIfNeeded() {
        guard installedHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            carbonHotkeyEventHandler,
            1,
            &eventType,
            nil,
            &installedHandlerRef
        )
    }

    fileprivate static func handleHotKeyEvent(_ eventRef: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        handlers[hotKeyID.id]?()
        return noErr
    }
}
