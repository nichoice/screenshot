import CoreGraphics
import Foundation

struct CaptureSelection: Equatable {
    let start: CGPoint
    let end: CGPoint

    var normalizedRect: CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
