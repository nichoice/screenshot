import AppKit
import SwiftUI

@MainActor
final class EditorWindowController {
    private var window: NSWindow?

    func show(result: CaptureResult, document: AnnotationDocument) {
        let view = AnnotationCanvasView(image: result.image, document: document)
        let hosting = NSHostingView(rootView: view.frame(minWidth: 800, minHeight: 600))
        let window = NSWindow(
            contentRect: CGRect(x: 120, y: 120, width: 900, height: 680),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        window.title = "Screenshot Editor"
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
