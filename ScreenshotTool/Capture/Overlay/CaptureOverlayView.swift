import AppKit

final class CaptureOverlayView: NSView {
    var onSelectionChanged: ((CGPoint, CGPoint) -> Void)?
    var onSelectionCompleted: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?

    override var acceptsFirstResponder: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawDimmedBackdrop()

        guard let selectionRect else {
            drawStartHint()
            return
        }

        clearSelectionWindow(selectionRect)
        drawSelectionFrame(selectionRect)
        drawSelectionHandles(selectionRect)
        drawSelectionSizeLabel(selectionRect)
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        dragCurrent = dragStart
        if let dragStart {
            onSelectionChanged?(dragStart, dragStart)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
        dragCurrent = current
        onSelectionChanged?(dragStart, current)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        onSelectionCompleted?()
        dragStart = nil
        dragCurrent = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancelled?()
        }
    }
}

private extension CaptureOverlayView {
    var selectionRect: CGRect? {
        guard let dragStart, let dragCurrent else { return nil }
        let rect = CaptureSelection(start: dragStart, end: dragCurrent).normalizedRect
        return rect.width >= 1 || rect.height >= 1 ? rect : nil
    }

    func drawDimmedBackdrop() {
        NSColor.black.withAlphaComponent(0.42).setFill()
        bounds.fill()
    }

    func drawStartHint() {
        let message = "拖拽选择截图区域，按 Esc 取消"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.92),
            .shadow: textShadow
        ]
        let attributed = NSAttributedString(string: message, attributes: attributes)
        let size = attributed.size()
        let origin = CGPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        attributed.draw(at: origin)
    }

    func clearSelectionWindow(_ rect: CGRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.setBlendMode(.clear)
        context.fill(rect)
        context.restoreGState()
    }

    func drawSelectionFrame(_ rect: CGRect) {
        let borderStyle = CaptureOverlayContrast.borderStyle(forBackgroundLuminance: estimatedBackgroundLuminance)
        let primary = borderStyle == .light ? NSColor.white : NSColor.black
        let secondary = borderStyle == .light ? NSColor.black : NSColor.white
        let accent = NSColor.systemCyan

        drawStroke(rect.insetBy(dx: -2.5, dy: -2.5), color: secondary.withAlphaComponent(0.78), width: 5)
        drawStroke(rect.insetBy(dx: -0.5, dy: -0.5), color: primary.withAlphaComponent(0.98), width: 2)
        drawStroke(rect.insetBy(dx: 2, dy: 2), color: accent.withAlphaComponent(0.9), width: 1.5)
    }

    func drawSelectionHandles(_ rect: CGRect) {
        let points = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.midY),
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]

        for point in points {
            let handle = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
            let path = NSBezierPath(roundedRect: handle, xRadius: 2.5, yRadius: 2.5)
            NSColor.white.setFill()
            path.fill()
            NSColor.black.withAlphaComponent(0.74).setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }

    func drawSelectionSizeLabel(_ rect: CGRect) {
        let sizeText = "\(Int(rect.width.rounded())) x \(Int(rect.height.rounded()))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
            .shadow: textShadow
        ]
        let attributed = NSAttributedString(string: sizeText, attributes: attributes)
        let textSize = attributed.size()
        let labelRect = CGRect(
            x: rect.minX,
            y: max(bounds.minY + 12, rect.minY - textSize.height - 18),
            width: textSize.width + 18,
            height: textSize.height + 10
        )

        let background = NSBezierPath(roundedRect: labelRect, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.72).setFill()
        background.fill()
        NSColor.white.withAlphaComponent(0.18).setStroke()
        background.lineWidth = 1
        background.stroke()

        attributed.draw(at: CGPoint(x: labelRect.minX + 9, y: labelRect.minY + 5))
    }

    func drawStroke(_ rect: CGRect, color: NSColor, width: CGFloat) {
        let path = NSBezierPath(rect: rect)
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    var estimatedBackgroundLuminance: Double {
        effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 0.15 : 0.85
    }

    var textShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 8
        return shadow
    }
}
