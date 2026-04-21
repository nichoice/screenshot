import AppKit
import CoreGraphics
import CoreImage
import Foundation

struct AnnotationRenderer {
    func render(baseImage: CGImage, items: [AnnotationItem]) -> CGImage {
        let preprocessed = applyBlurItems(to: baseImage, items: items)

        guard let context = CGContext(
            data: nil,
            width: preprocessed.width,
            height: preprocessed.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)).rawValue
        ) else {
            return preprocessed
        }

        let canvasRect = CGRect(x: 0, y: 0, width: preprocessed.width, height: preprocessed.height)
        context.draw(preprocessed, in: canvasRect)
        context.setShouldAntialias(true)

        for item in items {
            switch item {
            case let .rectangle(rect, hex, lineWidth):
                context.setStrokeColor(Self.color(hex).cgColor)
                context.setLineWidth(lineWidth)
                context.stroke(rect)
            case let .ellipse(rect, hex, lineWidth):
                context.setStrokeColor(Self.color(hex).cgColor)
                context.setLineWidth(lineWidth)
                context.strokeEllipse(in: rect)
            case let .arrow(start, end, hex, lineWidth):
                context.setStrokeColor(Self.color(hex).cgColor)
                context.setFillColor(Self.color(hex).cgColor)
                context.setLineWidth(lineWidth)
                context.move(to: start)
                context.addLine(to: end)
                context.strokePath()
                drawArrowHead(in: context, start: start, end: end, color: Self.color(hex), lineWidth: lineWidth)
            case let .text(text, point, hex, fontSize):
                drawText(text, at: point, color: Self.color(hex), fontSize: fontSize, in: context)
            case let .pen(points, hex, lineWidth):
                guard let first = points.first else { continue }
                context.setStrokeColor(Self.color(hex).cgColor)
                context.setLineWidth(lineWidth)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.move(to: first)
                for point in points.dropFirst() {
                    context.addLine(to: point)
                }
                context.strokePath()
            case .blur:
                continue
            }
        }

        return context.makeImage() ?? preprocessed
    }

    private func applyBlurItems(to image: CGImage, items: [AnnotationItem]) -> CGImage {
        let context = CIContext(options: nil)
        var current = CIImage(cgImage: image)

        for item in items {
            guard case let .blur(rect, radius) = item else { continue }
            let blurred = current
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                .cropped(to: rect)
            current = blurred.composited(over: current)
        }

        return context.createCGImage(current, from: current.extent) ?? image
    }

    private func drawArrowHead(in context: CGContext, start: CGPoint, end: CGPoint, color: NSColor, lineWidth: Double) {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(10.0, lineWidth * 3.0)
        let left = CGPoint(
            x: end.x - headLength * cos(angle - .pi / 6.0),
            y: end.y - headLength * sin(angle - .pi / 6.0)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + .pi / 6.0),
            y: end.y - headLength * sin(angle + .pi / 6.0)
        )

        context.move(to: end)
        context.addLine(to: left)
        context.addLine(to: right)
        context.closePath()
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    private func drawText(_ text: String, at point: CGPoint, color: NSColor, fontSize: Double, in context: CGContext) {
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        attributed.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }

    static func nsColor(_ hex: String) -> NSColor {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)

        let red, green, blue: UInt64
        switch trimmed.count {
        case 6:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = 255
            green = 59
            blue = 48
        }

        return NSColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1.0
        )
    }

    private static func color(_ hex: String) -> NSColor {
        nsColor(hex)
    }
}
