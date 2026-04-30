import Foundation

public struct MacShotPreferences: Equatable {
    public var defaultColorHex: String
    public var defaultLineWidth: Double
    public var defaultFontSize: Double
    public var rememberLastTool: Bool
    public var includeCursor: Bool
    public var defaultSaveDirectoryPath: String?

    public init(
        defaultColorHex: String,
        defaultLineWidth: Double,
        defaultFontSize: Double,
        rememberLastTool: Bool,
        includeCursor: Bool,
        defaultSaveDirectoryPath: String? = nil
    ) {
        self.defaultColorHex = defaultColorHex
        self.defaultLineWidth = defaultLineWidth
        self.defaultFontSize = defaultFontSize
        self.rememberLastTool = rememberLastTool
        self.includeCursor = includeCursor
        self.defaultSaveDirectoryPath = defaultSaveDirectoryPath
    }

    public static let defaults = MacShotPreferences(
        defaultColorHex: "#FF3B30",
        defaultLineWidth: 4,
        defaultFontSize: 16,
        rememberLastTool: true,
        includeCursor: false,
        defaultSaveDirectoryPath: nil
    )
}
