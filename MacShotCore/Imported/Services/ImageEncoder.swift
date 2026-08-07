import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Screenshot image encoding trimmed for the embedded screenshot-only core.
enum ImageEncoder {
    enum Format: String {
        case png
        case jpeg
        case heic
        case webp
    }

    static var format: Format {
        guard
            let raw = UserDefaults.standard.string(forKey: "imageFormat"),
            let format = Format(rawValue: raw)
        else {
            return .png
        }
        return format == .webp ? .png : format
    }

    static var quality: CGFloat {
        if let quality = UserDefaults.standard.object(forKey: "imageQuality") as? Double {
            return CGFloat(max(0.1, min(1.0, quality)))
        }
        return 0.85
    }

    static var downscaleRetina: Bool {
        UserDefaults.standard.bool(forKey: "downscaleRetina")
    }

    static var fileExtension: String {
        switch format {
        case .png, .webp:
            return "png"
        case .jpeg:
            return "jpg"
        case .heic:
            return "heic"
        }
    }

    static var utType: UTType {
        switch format {
        case .png, .webp:
            return .png
        case .jpeg:
            return .jpeg
        case .heic:
            return .heic
        }
    }

    static func encode(_ image: NSImage) -> Data? {
        guard let cgImage = makeCGImage(image) else { return nil }
        let outputImage = downscaledImageIfNeeded(cgImage, logicalSize: image.size)

        switch format {
        case .png, .webp:
            return encodeWithCGImageDestination(
                cgImage: outputImage,
                type: "public.png",
                lossyQuality: nil
            )
        case .jpeg:
            return encodeWithCGImageDestination(
                cgImage: outputImage,
                type: "public.jpeg",
                lossyQuality: quality
            )
        case .heic:
            return encodeWithCGImageDestination(
                cgImage: outputImage,
                type: "public.heic",
                lossyQuality: quality
            )
        }
    }

    static func copyToClipboard(_ image: NSImage) {
        guard let cgImage = makeCGImage(image) else { return }
        let outputImage = downscaledImageIfNeeded(cgImage, logicalSize: image.size)
        guard
            let data = encodeWithCGImageDestination(
                cgImage: outputImage,
                type: "public.png",
                lossyQuality: nil
            )
        else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.png], owner: nil)
        pasteboard.setData(data, forType: .png)
    }

    private static func makeCGImage(_ image: NSImage) -> CGImage? {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return cgImage
        }
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.cgImage
    }

    private static func downscaledImageIfNeeded(_ image: CGImage, logicalSize: NSSize) -> CGImage {
        guard downscaleRetina else { return image }

        let logicalWidth = Int(logicalSize.width)
        let logicalHeight = Int(logicalSize.height)
        guard logicalWidth > 0, logicalHeight > 0,
              image.width > logicalWidth, image.height > logicalHeight else {
            return image
        }

        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard
            let context = CGContext(
                data: nil,
                width: logicalWidth,
                height: logicalHeight,
                bitsPerComponent: 8,
                bytesPerRow: logicalWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: logicalWidth, height: logicalHeight))
        return context.makeImage() ?? image
    }

    private static func encodeWithCGImageDestination(
        cgImage: CGImage,
        type: String,
        lossyQuality: CGFloat?
    ) -> Data? {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                type as CFString,
                1,
                nil
            )
        else {
            return nil
        }

        var properties: [String: Any] = [:]
        if let lossyQuality {
            properties[kCGImageDestinationLossyCompressionQuality as String] = lossyQuality
        }

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}
