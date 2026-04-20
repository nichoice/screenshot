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
            MainWindowView(viewModel: environment.mainWindowViewModel)
        }
        Settings {
            SettingsWindowView(viewModel: environment.settingsWindowViewModel)
        }
    }
}
