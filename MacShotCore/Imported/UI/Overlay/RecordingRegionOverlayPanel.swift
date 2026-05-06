import Cocoa

@MainActor
protocol RecordingRegionOverlayPresenting: AnyObject {
    var excludedWindowNumber: CGWindowID { get }

    func show(relativeTo screenRect: NSRect, screen: NSScreen)
    func close()
}

@MainActor
final class RecordingRegionOverlayPanel: NSPanel, RecordingRegionOverlayPresenting {
    private let overlayView = RecordingRegionOverlayView(frame: .zero)
    private var screenFrame: NSRect = .zero

    var excludedWindowNumber: CGWindowID {
        CGWindowID(windowNumber)
    }

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar + 1
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        contentView = overlayView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(relativeTo screenRect: NSRect, screen: NSScreen) {
        screenFrame = screen.frame
        setFrame(screen.frame, display: false)
        overlayView.frame = NSRect(origin: .zero, size: screen.frame.size)
        overlayView.selectionRect = NSRect(
            x: screenRect.minX - screen.frame.minX,
            y: screenRect.minY - screen.frame.minY,
            width: screenRect.width,
            height: screenRect.height
        )
        overlayView.needsDisplay = true
        orderFrontRegardless()
    }
}

@MainActor
private final class RecordingRegionOverlayView: NSView {
    var selectionRect: NSRect = .zero

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard selectionRect.width > 1, selectionRect.height > 1 else { return }

        drawDimmedOutsideSelection()
        drawSelectionBorder()
    }

    private func drawDimmedOutsideSelection() {
        let fullPath = NSBezierPath(rect: bounds)
        let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 4, yRadius: 4)
        fullPath.append(selectionPath.reversed)
        fullPath.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.46).setFill()
        fullPath.fill()
    }

    private func drawSelectionBorder() {
        let borderPath = NSBezierPath(roundedRect: selectionRect, xRadius: 4, yRadius: 4)
        borderPath.lineWidth = 2
        NSColor.systemGreen.setStroke()
        borderPath.stroke()

        drawCornerAccents()
    }

    private func drawCornerAccents() {
        let length: CGFloat = 24
        let inset: CGFloat = 0
        let lineWidth: CGFloat = 4
        let path = NSBezierPath()

        path.move(to: NSPoint(x: selectionRect.minX + inset, y: selectionRect.minY + length))
        path.line(to: NSPoint(x: selectionRect.minX + inset, y: selectionRect.minY + inset))
        path.line(to: NSPoint(x: selectionRect.minX + length, y: selectionRect.minY + inset))

        path.move(to: NSPoint(x: selectionRect.maxX - length, y: selectionRect.minY + inset))
        path.line(to: NSPoint(x: selectionRect.maxX - inset, y: selectionRect.minY + inset))
        path.line(to: NSPoint(x: selectionRect.maxX - inset, y: selectionRect.minY + length))

        path.move(to: NSPoint(x: selectionRect.maxX - inset, y: selectionRect.maxY - length))
        path.line(to: NSPoint(x: selectionRect.maxX - inset, y: selectionRect.maxY - inset))
        path.line(to: NSPoint(x: selectionRect.maxX - length, y: selectionRect.maxY - inset))

        path.move(to: NSPoint(x: selectionRect.minX + length, y: selectionRect.maxY - inset))
        path.line(to: NSPoint(x: selectionRect.minX + inset, y: selectionRect.maxY - inset))
        path.line(to: NSPoint(x: selectionRect.minX + inset, y: selectionRect.maxY - length))

        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        NSColor.systemGreen.setStroke()
        path.stroke()
    }
}
