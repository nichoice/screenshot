import XCTest
import AppKit
@testable import ScreenshotTool

final class AppThemeControllerTests: XCTestCase {
    @MainActor
    func testResolveExplicitDarkThemeReturnsDark() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.dark, systemIsDark: false), .dark)
    }

    @MainActor
    func testResolveFollowSystemUsesSystemAppearance() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: true), .dark)
        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: false), .light)
    }

    @MainActor
    func testColorSchemeOverrideReturnsNilForFollowSystem() {
        let controller = AppThemeController()

        XCTAssertNil(controller.colorSchemeOverride(for: .followSystem))
    }

    @MainActor
    func testThemeControllerTracksPreferencesStoreUpdates() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = AppPreferencesStore(userDefaults: defaults)
        let controller = AppThemeController(preferencesStore: store)

        store.updateApp { $0.themePreference = .dark }

        XCTAssertEqual(controller.preferredColorScheme, .dark)
    }

    @MainActor
    func testAppAppearanceNameUsesDarkAquaForDarkTheme() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.appAppearanceName(for: .dark), .darkAqua)
        XCTAssertNil(controller.appAppearanceName(for: .followSystem))
    }

    @MainActor
    func testResolvedLogoAssetNameUsesThemeSpecificArtwork() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.logoAssetName(for: .light), "AppLogoLight")
        XCTAssertEqual(controller.logoAssetName(for: .dark), "AppLogoDark")
    }
}
