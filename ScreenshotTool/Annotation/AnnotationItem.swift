import CoreGraphics
import Foundation

enum AnnotationItem: Equatable {
    case rectangle(CGRect, String, Double)
    case arrow(CGPoint, CGPoint, String, Double)
    case text(String, CGPoint, String, Double)
    case pen([CGPoint], String, Double)
    case blur(CGRect, Double)
}
