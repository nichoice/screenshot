import AppKit

final class CaptureOverlayView: NSView {
    var onSelectionChanged: ((CGPoint, CGPoint) -> Void)?
    var onSelectionCompleted: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var dragStart: CGPoint?

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        if let dragStart {
            onSelectionChanged?(dragStart, dragStart)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
        onSelectionChanged?(dragStart, current)
    }

    override func mouseUp(with event: NSEvent) {
        onSelectionCompleted?()
        dragStart = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancelled?()
        }
    }
}
