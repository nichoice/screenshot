import Foundation

enum AppThemePreference: String, Codable, CaseIterable {
    case light
    case dark
    case followSystem
}

enum ResolvedAppTheme: Equatable {
    case light
    case dark
}
