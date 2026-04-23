import AppKit

protocol CaptureWindowRectProviding {
    func appKitWindowRect(containing globalPoint: CGPoint) -> CGRect?
}

struct WindowListCaptureWindowProvider: CaptureWindowRectProviding {
    let excludedOwnerPID: pid_t

    init(excludedOwnerPID: pid_t = getpid()) {
        self.excludedOwnerPID = excludedOwnerPID
    }

    func appKitWindowRect(containing globalPoint: CGPoint) -> CGRect? {
        guard let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(globalPoint) })?.frame ?? NSScreen.main?.frame,
              let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let cgPoint = CaptureCoordinateConverter.appKitPointToCGWindowPoint(globalPoint, screenFrame: screenFrame)

        for info in windowInfo {
            guard let ownerPID = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  ownerPID != excludedOwnerPID else {
                continue
            }

            let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
            let alpha = (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1
            guard layer == 0, alpha > 0.01 else {
                continue
            }

            guard let boundsDictionary = info[kCGWindowBounds as String] as? [String: Any],
                  let cgWindowRect = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary),
                  cgWindowRect.width >= 40,
                  cgWindowRect.height >= 40,
                  cgWindowRect.contains(cgPoint) else {
                continue
            }

            let appKitRect = CaptureCoordinateConverter.cgWindowRectToAppKitRect(cgWindowRect, screenFrame: screenFrame)
            if appKitRect.contains(globalPoint) {
                return appKitRect
            }
        }

        return nil
    }
}

final class CaptureOverlayView: NSView {
    var onSelectionChanged: ((CGPoint, CGPoint) -> Void)?
    var onSelectionCompleted: (() -> Void)?
    var onCancelled: (() -> Void)?

    private let screenFrame: CGRect
    private let windowRectProvider: CaptureWindowRectProviding
    private var interactionState = CaptureOverlayInteractionState()
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    init(
        frame frameRect: NSRect,
        screenFrame: CGRect,
        windowRectProvider: CaptureWindowRectProviding = WindowListCaptureWindowProvider()
    ) {
        self.screenFrame = screenFrame
        self.windowRectProvider = windowRectProvider
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        interactionState.availableRect = bounds
    }

    required init?(coder: NSCoder) {
        self.screenFrame = .zero
        self.windowRectProvider = WindowListCaptureWindowProvider()
        super.init(coder: coder)
        wantsLayer = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        interactionState.availableRect = bounds

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawDimmedBackdrop()

        if let selectionRect = interactionState.selectionRect {
            clearSelectionWindow(selectionRect)
            drawSelectionFrame(selectionRect)
            drawSelectionHandles(selectionRect)
            drawSelectionSizeLabel(selectionRect)
            drawSelectionHint(selectionRect)
            return
        }

        if let hoveredWindowRect = interactionState.hoveredWindowRect {
            clearSelectionWindow(hoveredWindowRect)
            drawHoveredWindowFrame(hoveredWindowRect)
            drawWindowHoverHint(hoveredWindowRect)
            return
        }

        drawStartHint()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateHoveredWindow(forLocalPoint: point)
        interactionState.handleMouseDown(at: point)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        apply(interactionState.handleMouseDragged(to: point))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        apply(interactionState.handleMouseUp(at: point))
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        updateHoveredWindow(forLocalPoint: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        interactionState.hoveredWindowRect = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            interactionState.cancel()
            onCancelled?()
        }
    }
}

private extension CaptureOverlayView {
    func apply(_ actions: [CaptureOverlayInteractionAction]) {
        for action in actions {
            switch action {
            case let .selectionUpdated(rect):
                onSelectionChanged?(rect.origin, CGPoint(x: rect.maxX, y: rect.maxY))
            case .selectionConfirmed:
                onSelectionCompleted?()
            }
        }
    }

    func updateHoveredWindow(forLocalPoint point: CGPoint) {
        let globalPoint = CaptureCoordinateConverter.localPointToGlobal(point, screenFrame: screenFrame)
        if let globalRect = windowRectProvider.appKitWindowRect(containing: globalPoint) {
            interactionState.hoveredWindowRect = CaptureCoordinateConverter.globalRectToLocal(globalRect, screenFrame: screenFrame)
        } else {
            interactionState.hoveredWindowRect = nil
        }
    }

    func drawDimmedBackdrop() {
        NSColor.black.withAlphaComponent(0.42).setFill()
        bounds.fill()
    }

    func drawStartHint() {
        let message = "按住拖拽，松手立即进入编辑；单击窗口立即吸附编辑，按 Esc 取消"
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

    func drawSelectionHint(_ rect: CGRect) {
        drawHint("松手完成截图", near: rect)
    }

    func drawWindowHoverHint(_ rect: CGRect) {
        drawHint("单击窗口立即编辑", near: rect)
    }

    func drawHint(_ message: String, near rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
            .shadow: textShadow
        ]
        let attributed = NSAttributedString(string: message, attributes: attributes)
        let textSize = attributed.size()
        let labelRect = CGRect(
            x: rect.maxX - textSize.width - 18,
            y: min(bounds.maxY - textSize.height - 18, rect.maxY + 12),
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

    func drawHoveredWindowFrame(_ rect: CGRect) {
        let shadowRect = rect.insetBy(dx: -3, dy: -3)
        drawStroke(shadowRect, color: NSColor.black.withAlphaComponent(0.65), width: 6)

        let path = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        let dashPattern: [CGFloat] = [10, 6]
        path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
        path.lineWidth = 2
        NSColor.systemYellow.withAlphaComponent(0.96).setStroke()
        path.stroke()
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
