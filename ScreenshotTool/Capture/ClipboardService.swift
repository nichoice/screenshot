import CoreGraphics
import Foundation

protocol ClipboardService {
    func copy(image: CGImage)
    func copy(text: String)
}
