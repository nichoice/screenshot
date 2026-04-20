import CoreGraphics
import CoreImage
import Foundation

struct AnnotationRenderer {
    func render(baseImage: CGImage, items: [AnnotationItem]) -> CGImage {
        let ciImage = CIImage(cgImage: baseImage)
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent) ?? baseImage
    }
}
