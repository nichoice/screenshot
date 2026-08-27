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
    private var startCapture: () -> Void
    private var startBatchCapture: () -> Void

    init(
        openSettings: @escaping () -> Void,
        startCapture: @escaping () -> Void,
        startBatchCapture: @escaping () -> Void = {}
    ) {
        self.openSettings = openSettings
        self.startCapture = startCapture
        self.startBatchCapture = startBatchCapture
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                item.button?.title = "SnapPii"
                let menu = NSMenu()
                menu.addItem(withTitle: "Capture", action: #selector(handleCapture), keyEquivalent: "")
                menu.addItem(withTitle: "连续截图", action: #selector(handleBatchCapture), keyEquivalent: "")
                menu.addItem(withTitle: "Settings", action: #selector(handleSettings), keyEquivalent: "")
                item.menu = menu
                statusItem = item
            }
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func replaceStartCaptureAction(_ action: @escaping () -> Void) {
        startCapture = action
    }

    func replaceStartBatchCaptureAction(_ action: @escaping () -> Void) {
        startBatchCapture = action
    }

    @objc private func handleCapture() {
        startCapture()
    }

    @objc private func handleBatchCapture() {
        startBatchCapture()
    }

    @objc private func handleSettings() {
        openSettings()
    }
}
