import AppKit

@MainActor
final class PinWindowController {
    private var windows: [NSWindow] = []

    func show(image: CGImage) {
        let imageView = NSImageView(image: NSImage(cgImage: image, size: .zero))
        let window = NSWindow(
            contentRect: CGRect(x: 160, y: 160, width: 360, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.contentView = imageView
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}
