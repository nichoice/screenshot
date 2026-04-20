import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(environment?.preferencesStore.appPreferences.stayResidentAfterClosingWindow ?? true)
    }
}
