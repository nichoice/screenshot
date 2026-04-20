import SwiftUI

@main
struct ScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup(environment.windowTitle) {
            MainWindowView(title: environment.windowTitle)
        }
        Settings {
            SettingsWindowView()
        }
    }
}
