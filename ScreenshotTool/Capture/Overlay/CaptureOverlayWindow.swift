import AppKit

final class CaptureOverlayWindow: NSWindow {
    var onCancelled: (() -> Void)?

    init(contentView: NSView, frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancelled?()
            return
        }

        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancelled?()
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == 53 {
            onCancelled?()
            return
        }

        super.sendEvent(event)
    }
}
