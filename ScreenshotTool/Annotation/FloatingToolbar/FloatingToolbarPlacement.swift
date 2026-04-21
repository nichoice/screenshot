import CoreGraphics
import Foundation

struct FloatingToolbarPlacement {
    static func resolve(selectionRect: CGRect, availableRect: CGRect, toolbarSize: CGSize) -> CGRect {
        let preferredY = selectionRect.maxY + 8
        let centeredX = selectionRect.midX - (toolbarSize.width / 2)
        let clampedX = min(
            max(availableRect.minX, centeredX),
            max(availableRect.minX, availableRect.maxX - toolbarSize.width)
        )
        if preferredY + toolbarSize.height <= availableRect.maxY {
            return CGRect(x: clampedX, y: preferredY, width: toolbarSize.width, height: toolbarSize.height)
        }

        let fallbackY = max(availableRect.minY, selectionRect.minY - toolbarSize.height - 8)
        return CGRect(x: clampedX, y: fallbackY, width: toolbarSize.width, height: toolbarSize.height)
    }
}
