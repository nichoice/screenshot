import AppKit
import CoreImage
import Vision

protocol BackgroundRemoving {
    func removeBackground(from image: NSImage) async throws -> NSImage
}

struct VisionBackgroundRemover: BackgroundRemoving {
    enum Failure: Error {
        case missingCGImage
        case missingResult
        case missingFilter
        case missingOutputImage
        case missingRenderedImage
    }

    func removeBackground(from image: NSImage) async throws -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw Failure.missingCGImage
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let result = request.results?.first else {
                throw Failure.missingResult
            }

            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )

            let originalCIImage = CIImage(cgImage: cgImage)
            let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

            guard let filter = CIFilter(name: "CIBlendWithMask") else {
                throw Failure.missingFilter
            }
            filter.setValue(originalCIImage, forKey: kCIInputImageKey)
            filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)
            filter.setValue(
                CIImage(color: .clear).cropped(to: originalCIImage.extent),
                forKey: kCIInputBackgroundImageKey
            )

            guard let outputCIImage = filter.outputImage else {
                throw Failure.missingOutputImage
            }

            guard let finalCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) else {
                throw Failure.missingRenderedImage
            }

            return NSImage(cgImage: finalCGImage, size: image.size)
        }.value
    }
}
