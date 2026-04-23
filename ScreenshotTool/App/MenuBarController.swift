import AppKit
import Foundation

@MainActor
protocol MenuBarVisibilityControlling: AnyObject {
    func setVisible(_ visible: Bool)
}

@MainActor
final class MenuBarController: MenuBarVisibilityControlling {
    private var statusItem: NSStatusItem?
    private let openSettings: () -> Void
    private let startCapture: () -> Void

    init(openSettings: @escaping () -> Void, startCapture: @escaping () -> Void) {
        self.openSettings = openSettings
        self.startCapture = startCapture
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                item.button?.title = "Shot"
                let menu = NSMenu()
                menu.addItem(withTitle: "Capture", action: #selector(handleCapture), keyEquivalent: "")
                menu.addItem(withTitle: "Settings", action: #selector(handleSettings), keyEquivalent: "")
                item.menu = menu
                statusItem = item
            }
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc private func handleCapture() {
        startCapture()
    }

    @objc private func handleSettings() {
        openSettings()
    }
}
