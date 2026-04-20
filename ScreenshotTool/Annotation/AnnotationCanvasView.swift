import AppKit
import SwiftUI

struct AnnotationCanvasView: NSViewRepresentable {
    let image: CGImage
    @ObservedObject var document: AnnotationDocument
    @ObservedObject var editorState: AnnotationEditorState

    func makeNSView(context: Context) -> AnnotationCanvasNSView {
        AnnotationCanvasNSView(image: image, document: document, editorState: editorState)
    }

    func updateNSView(_ nsView: AnnotationCanvasNSView, context: Context) {
        nsView.image = image
        nsView.document = document
        nsView.editorState = editorState
        nsView.needsDisplay = true
    }
}

final class AnnotationCanvasNSView: NSView {
    var image: CGImage
    var document: AnnotationDocument
    var editorState: AnnotationEditorState

    private let renderer = AnnotationRenderer()
    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var currentPath: [CGPoint] = []

    init(image: CGImage, document: AnnotationDocument, editorState: AnnotationEditorState) {
        self.image = image
        self.document = document
        self.editorState = editorState
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
        self.wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let preview = editorState.previewItem(from: dragStart, to: dragCurrent, path: currentPath)
        let rendered = renderer.render(
            baseImage: image,
            items: preview.map { document.items + [$0] } ?? document.items
        )
        NSImage(cgImage: rendered, size: bounds.size).draw(in: bounds)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        switch editorState.selectedTool {
        case .text:
            editorState.commitClick(at: point)
            needsDisplay = true
        case .pen:
            currentPath = [point]
            dragStart = point
            dragCurrent = point
            needsDisplay = true
        default:
            dragStart = point
            dragCurrent = point
            needsDisplay = true
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if editorState.selectedTool == .pen {
            currentPath.append(point)
        } else {
            dragCurrent = point
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        switch editorState.selectedTool {
        case .pen:
            currentPath.append(point)
            editorState.commitPath(currentPath)
        case .text:
            break
        default:
            if let dragStart {
                editorState.commitDrag(from: dragStart, to: point)
            }
        }

        dragStart = nil
        dragCurrent = nil
        currentPath = []
        needsDisplay = true
    }
}
