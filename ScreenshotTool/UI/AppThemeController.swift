import Combine
import Foundation
import AppKit
import SwiftUI

@MainActor
final class AppThemeController: ObservableObject {
    @Published private(set) var themePreference: AppThemePreference

    private var cancellables: Set<AnyCancellable> = []

    init(preferencesStore: AppPreferencesStore? = nil) {
        self.themePreference = preferencesStore?.appPreferences.themePreference ?? .followSystem

        preferencesStore?.$appPreferences
            .map(\.themePreference)
            .removeDuplicates()
            .sink { [weak self] preference in
                self?.themePreference = preference
            }
            .store(in: &cancellables)
    }

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

    func colorSchemeOverride(for preference: AppThemePreference) -> ColorScheme? {
        switch preference {
        case .light:
            .light
        case .dark:
            .dark
        case .followSystem:
            nil
        }
    }

    var preferredColorScheme: ColorScheme? {
        colorSchemeOverride(for: themePreference)
    }

    func appAppearanceName(for preference: AppThemePreference) -> NSAppearance.Name? {
        switch preference {
        case .light:
            .aqua
        case .dark:
            .darkAqua
        case .followSystem:
            nil
        }
    }

    var preferredAppAppearanceName: NSAppearance.Name? {
        appAppearanceName(for: themePreference)
    }
}
