import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var environment: AppEnvironment?
    private var cancellables: Set<AnyCancellable> = []
    private var appearanceObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(AppPresentationPolicy.backgroundResidentActivationPolicy)
        environment?.start()
        guard let themeController = environment?.themeController else { return }

        applyTheme(themeController)
        themeController.$themePreference
            .sink { [weak self, weak themeController] _ in
                guard let themeController else { return }
                self?.applyTheme(themeController)
            }
            .store(in: &cancellables)

        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self, weak themeController] _ in
            Task { @MainActor in
                guard let themeController else { return }
                self?.applyTheme(themeController)
            }
        }
    }

    deinit {
        if let appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(appearanceObserver)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        AppPresentationPolicy.shouldTerminateAfterLastWindowClosed
    }

    private func applyTheme(_ themeController: AppThemeController) {
        applyAppearance(named: themeController.preferredAppAppearanceName)
        applyApplicationIcon(using: themeController)
    }

    private func applyAppearance(named appearanceName: NSAppearance.Name?) {
        if let appearanceName {
            NSApp.appearance = NSAppearance(named: appearanceName)
        } else {
            NSApp.appearance = nil
        }
    }

    private func applyApplicationIcon(using themeController: AppThemeController) {
        let resolvedTheme = themeController.resolve(themeController.themePreference, systemIsDark: systemIsDark)
        let logoAssetName = themeController.logoAssetName(for: resolvedTheme)
        guard let image = NSImage(named: logoAssetName) else { return }

        NSApp.applicationIconImage = image
    }

    private var systemIsDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
