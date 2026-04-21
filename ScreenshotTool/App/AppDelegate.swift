import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    var environment: AppEnvironment?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment?.start()
        guard let themeController = environment?.themeController else { return }

        applyAppearance(named: themeController.preferredAppAppearanceName)
        themeController.$themePreference
            .map { [weak themeController] _ in themeController?.preferredAppAppearanceName }
            .sink { [weak self] appearanceName in
                self?.applyAppearance(named: appearanceName ?? nil)
            }
            .store(in: &cancellables)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(environment?.preferencesStore.appPreferences.stayResidentAfterClosingWindow ?? true)
    }

    private func applyAppearance(named appearanceName: NSAppearance.Name?) {
        if let appearanceName {
            NSApp.appearance = NSAppearance(named: appearanceName)
        } else {
            NSApp.appearance = nil
        }
    }
}
