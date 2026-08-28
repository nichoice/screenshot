import Foundation

enum HotkeyModifier: String, Codable, CaseIterable {
    case command
    case option
    case control
    case shift

    var displayName: String {
        switch self {
        case .command:
            "Command"
        case .option:
            "Option"
        case .control:
            "Control"
        case .shift:
            "Shift"
        }
    }
}

struct GlobalHotkey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: [HotkeyModifier]

    static let defaultCapture = GlobalHotkey(keyCode: 21, modifiers: [.command, .shift])

    var isSupportedCaptureHotkey: Bool {
        normalized != Self.systemReservedCaptureHotkey
    }

    var displayName: String {
        let modifierNames = normalizedModifiers.map(\.displayName)
        return (modifierNames + [Self.keyName(for: keyCode)]).joined(separator: " + ")
    }

    var normalized: GlobalHotkey {
        GlobalHotkey(keyCode: keyCode, modifiers: normalizedModifiers)
    }

    private var normalizedModifiers: [HotkeyModifier] {
        Self.modifierDisplayOrder.filter { modifiers.contains($0) }
    }

    private static let modifierDisplayOrder: [HotkeyModifier] = [.command, .shift, .option, .control]

    private static let systemReservedCaptureHotkey = GlobalHotkey(
        keyCode: 0,
        modifiers: [.command, .shift]
    )

    private static func keyName(for keyCode: UInt32) -> String {
        keyCodeNames[keyCode] ?? "Key \(keyCode)"
    }

    private static let keyCodeNames: [UInt32: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        24: "=",
        25: "9",
        26: "7",
        27: "-",
        28: "8",
        29: "0",
        30: "]",
        31: "O",
        32: "U",
        33: "[",
        34: "I",
        35: "P",
        37: "L",
        38: "J",
        39: "'",
        40: "K",
        41: ";",
        42: "\\",
        43: ",",
        44: "/",
        45: "N",
        46: "M",
        47: ".",
        49: "Space",
        50: "`",
        51: "Delete",
        53: "Esc",
        65: ".",
        67: "*",
        69: "+",
        71: "Clear",
        75: "/",
        76: "Enter",
        78: "-",
        81: "=",
        82: "0",
        83: "1",
        84: "2",
        85: "3",
        86: "4",
        87: "5",
        88: "6",
        89: "7",
        91: "8",
        92: "9",
        96: "F5",
        97: "F6",
        98: "F7",
        99: "F3",
        100: "F8",
        101: "F9",
        103: "F11",
        105: "F13",
        106: "F16",
        107: "F14",
        109: "F10",
        111: "F12",
        113: "F15",
        114: "Help",
        115: "Home",
        116: "Page Up",
        117: "Forward Delete",
        118: "F4",
        119: "End",
        120: "F2",
        121: "Page Down",
        122: "F1",
        123: "Left",
        124: "Right",
        125: "Down",
        126: "Up",
    ]
}

enum CaptureOutputAction: String, Codable, CaseIterable {
    case copyOnly
    case saveOnly
    case copyAndSave
    case openEditor
}

enum CaptureImageFormat: String, Codable, CaseIterable {
    case png
    case jpeg
}

struct AppPreferences: Codable, Equatable {
    var stayResidentAfterClosingWindow: Bool = true
    var showsMenuBarIcon: Bool = true
    var launchAtLogin: Bool = false
    var themePreference: AppThemePreference = .followSystem
}

struct CapturePreferences: Codable, Equatable {
    var hotkey: GlobalHotkey = .defaultCapture
    var defaultSaveDirectoryPath: String? = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path
    var defaultOutputAction: CaptureOutputAction = .copyAndSave
    var imageFormat: CaptureImageFormat = .png
    var includeCursor: Bool = false
    var playCaptureSound: Bool = false
}

struct AnnotationPreferences: Codable, Equatable {
    var defaultColorHex: String = "#FF3B30"
    var defaultLineWidth: Double = 4
    var defaultFontSize: Double = 16
    var rememberLastTool: Bool = true
    var pinWindowsFloatOnTop: Bool = true
    var historyLimit: Int = 20
}

struct InputMethodPreferences: Codable, Equatable {
    var isEnabled: Bool = true
    var globalDefaultInputSourceID: String? = nil
}
