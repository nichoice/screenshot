import SwiftUI

@main
struct ScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.bootstrap()
    @StateObject private var themeController: AppThemeController

    init() {
        let environment = AppEnvironment.bootstrap()
        _environment = StateObject(wrappedValue: environment)
        _themeController = StateObject(wrappedValue: environment.themeController)
        appDelegate.environment = environment
    }

    var body: some Scene {
        WindowGroup(environment.windowTitle) {
            MainWindowRootView(
                mainViewModel: environment.mainWindowViewModel,
                settingsViewModel: environment.settingsWindowViewModel,
                windowRouter: environment.windowRouter
            )
            .preferredColorScheme(themeController.preferredColorScheme)
        }
        Window("SnapPii Settings", id: "settings") {
            SettingsWindowView(viewModel: environment.settingsWindowViewModel)
                .preferredColorScheme(themeController.preferredColorScheme)
        }
    }
}
