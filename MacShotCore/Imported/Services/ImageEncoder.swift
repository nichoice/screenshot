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
        guard let bitmap = makeBitmap(image) else { return nil }

        switch format {
        case .png, .webp:
            return encodePNG(bitmap: bitmap)
        case .jpeg:
            return encodeJPEG(bitmap: bitmap, quality: quality)
        case .heic:
            return encodeHEIC(bitmap: bitmap, quality: quality)
        }
    }

    static func copyToClipboard(_ image: NSImage) {
        guard let data = encodePNGDataForClipboard(image) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.png], owner: nil)
        pasteboard.setData(data, forType: .png)
    }

    private static func makeBitmap(_ image: NSImage) -> NSBitmapImageRep? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            guard
                let tiffData = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData)
            else {
                return nil
            }
            return bitmap
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard downscaleRetina else { return bitmap }

        let logicalWidth = Int(image.size.width)
        let logicalHeight = Int(image.size.height)
        guard bitmap.pixelsWide > logicalWidth, bitmap.pixelsHigh > logicalHeight else {
            return bitmap
        }

        let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
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
            return bitmap
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: logicalWidth, height: logicalHeight))
        guard let downscaled = context.makeImage() else { return bitmap }
        return NSBitmapImageRep(cgImage: downscaled)
    }

    private static func encodePNGDataForClipboard(_ image: NSImage) -> Data? {
        makeBitmap(image)?.representation(using: .png, properties: [:])
    }

    private static func encodePNG(bitmap: NSBitmapImageRep) -> Data? {
        guard let cgImage = bitmap.cgImage else {
            return bitmap.representation(using: .png, properties: [:])
        }
        return encodeWithCGImageDestination(cgImage: cgImage, type: "public.png", lossyQuality: nil)
    }

    private static func encodeJPEG(bitmap: NSBitmapImageRep, quality: CGFloat) -> Data? {
        guard let cgImage = bitmap.cgImage else {
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        }
        return encodeWithCGImageDestination(cgImage: cgImage, type: "public.jpeg", lossyQuality: quality)
    }

    private static func encodeHEIC(bitmap: NSBitmapImageRep, quality: CGFloat) -> Data? {
        guard let cgImage = bitmap.cgImage else { return nil }
        return encodeWithCGImageDestination(cgImage: cgImage, type: "public.heic", lossyQuality: quality)
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
