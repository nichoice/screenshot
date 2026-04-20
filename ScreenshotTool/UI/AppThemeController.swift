import Foundation

struct AppThemeController {
    func resolve(_ preference: AppThemePreference, systemIsDark: Bool) -> ResolvedAppTheme {
        switch preference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .followSystem:
            return systemIsDark ? .dark : .light
        }
    }
}
