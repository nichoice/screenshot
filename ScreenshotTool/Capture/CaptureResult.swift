import CoreGraphics
import Foundation

struct CaptureResult {
    let fullImage: CGImage
    let image: CGImage
    let selectionRect: CGRect
    let capturedAt: Date
}
