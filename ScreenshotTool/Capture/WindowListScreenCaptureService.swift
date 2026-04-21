import AppKit
import CoreGraphics
import Foundation

enum ScreenCaptureError: Error {
    case captureFailed
}

struct WindowListScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        let resolvedRect: CGRect
        if rect.isInfinite {
            resolvedRect = NSScreen.screens.reduce(into: CGRect.null) { partial, screen in
                partial = partial.union(screen.frame)
            }
        } else {
            resolvedRect = rect
        }

        guard let image = CGWindowListCreateImage(
            resolvedRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            throw ScreenCaptureError.captureFailed
        }

        return image
    }
}
