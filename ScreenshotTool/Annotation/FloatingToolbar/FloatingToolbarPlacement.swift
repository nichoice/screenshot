import CoreGraphics
import Foundation

struct FloatingToolbarPlacement {
    static func resolve(selectionRect: CGRect, availableRect: CGRect, toolbarSize: CGSize) -> CGRect {
        let preferredY = selectionRect.maxY + 8
        if preferredY + toolbarSize.height <= availableRect.maxY {
            return CGRect(x: selectionRect.minX, y: preferredY, width: toolbarSize.width, height: toolbarSize.height)
        }

        let fallbackY = max(availableRect.minY, selectionRect.minY - toolbarSize.height - 8)
        return CGRect(x: selectionRect.minX, y: fallbackY, width: toolbarSize.width, height: toolbarSize.height)
    }
}
