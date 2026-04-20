import CoreGraphics
import Foundation

enum ScreenCaptureError: Error {
    case captureFailed
}

struct WindowListScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        guard let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            throw ScreenCaptureError.captureFailed
        }

        return image
    }
}
