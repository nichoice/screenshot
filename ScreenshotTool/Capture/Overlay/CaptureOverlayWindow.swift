import AppKit

final class CaptureOverlayWindow: NSWindow {
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
    }
}
