import AppKit

final class EditorView: OverlayView {
    override var isEditorMode: Bool { true }
    override var isInsideScrollView: Bool { true }

    var drewFromCompositeCache = false

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    override func drawEditorBackground(context: NSGraphicsContext) {
        guard !beautifyEnabled else { return }

        if !isActivelyDrawing, let cached = cachedCompositedImage {
            cached.draw(in: selectionRect, from: .zero, operation: .copy, fraction: 1.0)
            drewFromCompositeCache = true
            return
        }

        drewFromCompositeCache = false
        screenshotImage?.draw(in: selectionRect, from: .zero, operation: .copy, fraction: 1.0)
    }

    override func shouldClipSelectionImage() -> Bool { false }

    override func shouldDrawSelectionBorder() -> Bool { false }

    override func shouldDrawSizeLabel() -> Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if selectionRect.contains(point) {
            super.mouseMoved(with: event)
        } else {
            NSCursor.arrow.set()
        }
    }

    override func shouldAllowSelectionResize() -> Bool { false }

    override func shouldAllowNewSelection() -> Bool { false }

    override func shouldAllowDetach() -> Bool { false }

    override func canPanAtOneX() -> Bool { false }

    override func clampZoomAnchorForEditor(r: NSRect, z: CGFloat, ac: NSPoint, av: inout NSPoint) {}

    override var captureDrawRect: NSRect { selectionRect }
}
