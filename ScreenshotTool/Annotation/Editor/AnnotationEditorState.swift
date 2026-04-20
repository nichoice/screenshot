import CoreGraphics
import Foundation

@MainActor
final class AnnotationEditorState: ObservableObject {
    let document: AnnotationDocument

    @Published var selectedTool: AnnotationTool = .rectangle
    @Published var strokeColorHex: String = "#FF3B30"
    @Published var lineWidth: Double = 4
    @Published var fontSize: Double = 16
    @Published var textValue: String = "Text"

    init(document: AnnotationDocument) {
        self.document = document
    }

    func commitDrag(from start: CGPoint, to end: CGPoint) {
        switch selectedTool {
        case .rectangle:
            document.add(.rectangle(normalizedRect(from: start, to: end), strokeColorHex, lineWidth))
        case .arrow:
            document.add(.arrow(start, end, strokeColorHex, lineWidth))
        case .blur:
            document.add(.blur(normalizedRect(from: start, to: end), max(4, lineWidth * 2)))
        case .pen, .text:
            return
        }
    }

    func commitPath(_ points: [CGPoint]) {
        guard selectedTool == .pen, !points.isEmpty else { return }
        document.add(.pen(points, strokeColorHex, lineWidth))
    }

    func commitClick(at point: CGPoint) {
        guard selectedTool == .text else { return }
        document.add(.text(textValue.isEmpty ? "Text" : textValue, point, strokeColorHex, fontSize))
    }

    func undo() {
        document.undo()
    }

    func clear() {
        document.clear()
    }

    func previewItem(from start: CGPoint?, to end: CGPoint?, path: [CGPoint]) -> AnnotationItem? {
        switch selectedTool {
        case .rectangle:
            guard let start, let end else { return nil }
            return .rectangle(normalizedRect(from: start, to: end), strokeColorHex, lineWidth)
        case .arrow:
            guard let start, let end else { return nil }
            return .arrow(start, end, strokeColorHex, lineWidth)
        case .blur:
            guard let start, let end else { return nil }
            return .blur(normalizedRect(from: start, to: end), max(4, lineWidth * 2))
        case .pen:
            guard !path.isEmpty else { return nil }
            return .pen(path, strokeColorHex, lineWidth)
        case .text:
            return nil
        }
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
