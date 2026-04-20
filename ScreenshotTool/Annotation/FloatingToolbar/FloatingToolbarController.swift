import AppKit
import SwiftUI

@MainActor
final class FloatingToolbarController {
    private var panel: NSPanel?

    func show(
        frame: CGRect,
        copyAction: @escaping () -> Void,
        saveAction: @escaping () -> Void,
        pinAction: @escaping () -> Void,
        editAction: @escaping () -> Void
    ) {
        let content = HStack {
            Button("Copy", action: copyAction)
            Button("Save", action: saveAction)
            Button("Pin", action: pinAction)
            Button("Edit", action: editAction)
        }
        .padding(10)

        let hosting = NSHostingView(rootView: content)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = hosting
        panel.level = .floating
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}
