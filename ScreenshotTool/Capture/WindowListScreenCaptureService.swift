import AppKit
import CoreGraphics
import Foundation

enum ScreenCaptureError: Error {
    case captureFailed
}

struct WindowListScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        let desktopRect = NSScreen.screens.reduce(into: CGRect.null) { partial, screen in
            partial = partial.union(screen.frame)
        }
        let targetRect = rect.isInfinite ? desktopRect : rect
        let intersectingScreens = NSScreen.screens.filter { $0.frame.intersects(targetRect) }
        guard !intersectingScreens.isEmpty else {
            throw ScreenCaptureError.captureFailed
        }

        let outputScale = intersectingScreens
            .map(\.backingScaleFactor)
            .max() ?? 1

        let outputWidth = max(1, Int((targetRect.width * outputScale).rounded(.up)))
        let outputHeight = max(1, Int((targetRect.height * outputScale).rounded(.up)))
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ScreenCaptureError.captureFailed
        }

        context.interpolationQuality = .high

        for screen in intersectingScreens {
            guard let displayID = screen.displayID,
                  let displayImage = CGDisplayCreateImage(displayID) else {
                continue
            }

            let intersection = targetRect.intersection(screen.frame)
            let scaleX = CGFloat(displayImage.width) / screen.frame.width
            let scaleY = CGFloat(displayImage.height) / screen.frame.height
            let cropRect = CGRect(
                x: (intersection.minX - screen.frame.minX) * scaleX,
                y: (screen.frame.maxY - intersection.maxY) * scaleY,
                width: intersection.width * scaleX,
                height: intersection.height * scaleY
            ).integral

            guard let cropped = displayImage.cropping(to: cropRect) else {
                continue
            }

            let destinationRect = CGRect(
                x: (intersection.minX - targetRect.minX) * outputScale,
                y: (intersection.minY - targetRect.minY) * outputScale,
                width: intersection.width * outputScale,
                height: intersection.height * outputScale
            )
            context.draw(cropped, in: destinationRect)
        }

        guard let image = context.makeImage() else {
            throw ScreenCaptureError.captureFailed
        }

        return image
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
