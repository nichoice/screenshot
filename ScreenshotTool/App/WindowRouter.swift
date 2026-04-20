import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    private var overlayWindows: [CaptureOverlayWindow] = []
    private let floatingToolbarController = FloatingToolbarController()
    private let editorWindowController = EditorWindowController()
    private let pinWindowController = PinWindowController()

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

    func presentFloatingToolbar(
        for result: CaptureResult,
        document: AnnotationDocument,
        outputService: CaptureOutputService,
        defaultSaveDirectory: URL,
        imageFormat: CaptureImageFormat
    ) {
        let frame = FloatingToolbarPlacement.resolve(
            selectionRect: result.selectionRect,
            availableRect: NSScreen.main?.visibleFrame ?? .zero,
            toolbarSize: CGSize(width: 260, height: 44)
        )

        floatingToolbarController.show(
            frame: frame,
            copyAction: { _ = try? outputService.copy(result: result, document: document) },
            saveAction: { _ = try? outputService.save(result: result, document: document, format: imageFormat, directory: defaultSaveDirectory) },
            pinAction: { self.pinWindowController.show(image: result.image) },
            editAction: { self.editorWindowController.show(result: result, document: document) }
        )
    }
}
