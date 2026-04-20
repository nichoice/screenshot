import Foundation

enum HotkeyModifier: String, Codable, CaseIterable {
    case command
    case option
    case control
    case shift
}

struct GlobalHotkey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: [HotkeyModifier]

    static let defaultCapture = GlobalHotkey(keyCode: 23, modifiers: [.command, .shift])
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
}

struct CapturePreferences: Codable, Equatable {
    var hotkey: GlobalHotkey = .defaultCapture
    var defaultSaveDirectoryPath: String? = nil
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
