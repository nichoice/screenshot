import CoreGraphics
import Foundation

protocol ScreenCaptureService: Sendable {
    func capture(rect: CGRect) throws -> CGImage
}
