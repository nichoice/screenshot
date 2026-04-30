import AppKit

final class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        guard let documentView else {
            return super.constrainBoundsRect(proposedBounds)
        }

        let docFrame = documentView.frame
        var rect = super.constrainBoundsRect(proposedBounds)
        let insets = enclosingScrollView?.contentInsets ?? NSEdgeInsetsZero
        let visibleWidth = rect.width - insets.left - insets.right
        let visibleHeight = rect.height - insets.top - insets.bottom

        if docFrame.width < visibleWidth {
            rect.origin.x = (docFrame.width - visibleWidth) / 2 - insets.left
        }
        if docFrame.height < visibleHeight {
            rect.origin.y = (docFrame.height - visibleHeight) / 2 - insets.bottom
        }
        return rect
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result === self, let documentView {
            let documentPoint = documentView.convert(point, from: self)
            if documentView.bounds.contains(documentPoint) {
                return documentView
            }
        }
        return result
    }

    override func scrollWheel(with event: NSEvent) {
        let isTrackpad = event.phase != [] || event.momentumPhase != []

        if !isTrackpad {
            guard let documentView else { return }
            let canScrollVertically = documentView.frame.height > bounds.height + 1
            guard canScrollVertically else { return }
            let delta = event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 1.0 : 10.0)
            scroll(NSPoint(x: bounds.origin.x, y: bounds.origin.y - delta))
            return
        }

        if let scrollView = enclosingScrollView {
            let docFrame = documentView?.frame ?? .zero
            let canScrollHorizontally = docFrame.width > bounds.width + 1
            let canScrollVertically = docFrame.height > bounds.height + 1
            if !canScrollHorizontally && !canScrollVertically {
                return
            }
            scrollView.horizontalScrollElasticity = canScrollHorizontally ? .allowed : .none
            scrollView.verticalScrollElasticity = canScrollVertically ? .allowed : .none
        }

        super.scrollWheel(with: event)
    }

    override func magnify(with event: NSEvent) {
        if let editorView = documentView as? OverlayView, editorView.isInsideScrollView {
            editorView.magnify(with: event)
            return
        }
        super.magnify(with: event)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}
