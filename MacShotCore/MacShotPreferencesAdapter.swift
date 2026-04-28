import Foundation

public final class MacShotPreferencesAdapter {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func apply(_ preferences: MacShotPreferences) {
        userDefaults.set(preferences.defaultColorHex, forKey: "ScreenshotTool.defaultColorHex")
        userDefaults.set(preferences.defaultLineWidth, forKey: "currentStrokeWidth")
        userDefaults.set(preferences.defaultFontSize, forKey: "textFontSize")
        userDefaults.set(preferences.rememberLastTool, forKey: "rememberLastTool")
        userDefaults.set(preferences.includeCursor, forKey: "captureCursor")
    }
}
