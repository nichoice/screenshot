import CoreGraphics
import Foundation

protocol ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage
}
