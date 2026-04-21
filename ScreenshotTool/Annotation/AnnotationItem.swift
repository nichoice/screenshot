import CoreGraphics
import Foundation

enum AnnotationItem: Equatable {
    case rectangle(CGRect, String, Double)
    case ellipse(CGRect, String, Double)
    case arrow(CGPoint, CGPoint, String, Double)
    case text(String, CGPoint, String, Double)
    case pen([CGPoint], String, Double)
    case blur(CGRect, Double)

    func offsetBy(dx: CGFloat, dy: CGFloat) -> AnnotationItem {
        switch self {
        case let .rectangle(rect, hex, lineWidth):
            return .rectangle(rect.offsetBy(dx: dx, dy: dy), hex, lineWidth)
        case let .ellipse(rect, hex, lineWidth):
            return .ellipse(rect.offsetBy(dx: dx, dy: dy), hex, lineWidth)
        case let .arrow(start, end, hex, lineWidth):
            return .arrow(
                CGPoint(x: start.x + dx, y: start.y + dy),
                CGPoint(x: end.x + dx, y: end.y + dy),
                hex,
                lineWidth
            )
        case let .text(text, point, hex, fontSize):
            return .text(text, CGPoint(x: point.x + dx, y: point.y + dy), hex, fontSize)
        case let .pen(points, hex, lineWidth):
            return .pen(points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }, hex, lineWidth)
        case let .blur(rect, radius):
            return .blur(rect.offsetBy(dx: dx, dy: dy), radius)
        }
    }
}
