import CoreGraphics
import Foundation

enum CaptureImageCropper {
    static func crop(image: CGImage, imageBounds: CGRect, selectionRect: CGRect) -> CGImage? {
        let scaleX = CGFloat(image.width) / imageBounds.width
        let scaleY = CGFloat(image.height) / imageBounds.height

        let cropRect = CGRect(
            x: (selectionRect.minX - imageBounds.minX) * scaleX,
            y: (imageBounds.maxY - selectionRect.maxY) * scaleY,
            width: selectionRect.width * scaleX,
            height: selectionRect.height * scaleY
        ).integral

        return image.cropping(to: cropRect)
    }
}
