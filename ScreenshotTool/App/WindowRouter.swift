import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    private var overlayWindows: [CaptureOverlayWindow] = []

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func showCaptureOverlay(
        onSelectionChanged: @escaping (CGPoint, CGPoint) -> Void,
        onSelectionCompleted: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) {
        hideCaptureOverlay()
        overlayWindows = NSScreen.screens.map { screen in
            let view = CaptureOverlayView(frame: screen.frame)
            view.onSelectionChanged = onSelectionChanged
            view.onSelectionCompleted = onSelectionCompleted
            view.onCancelled = onCancelled
            let window = CaptureOverlayWindow(contentView: view, frame: screen.frame)
            window.makeKeyAndOrderFront(nil)
            return window
        }
    }

    func hideCaptureOverlay() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }
}
