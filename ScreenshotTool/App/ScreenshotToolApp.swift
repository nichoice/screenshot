import SwiftUI

@main
struct ScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.bootstrap()

    init() {
        let environment = AppEnvironment.bootstrap()
        _environment = StateObject(wrappedValue: environment)
        appDelegate.environment = environment
    }

    var body: some Scene {
        WindowGroup(environment.windowTitle) {
            MainWindowRootView(
                mainViewModel: environment.mainWindowViewModel,
                settingsViewModel: environment.settingsWindowViewModel,
                windowRouter: environment.windowRouter
            )
        }
        Window("Settings", id: "settings") {
            SettingsWindowView(viewModel: environment.settingsWindowViewModel)
        }
    }
}
