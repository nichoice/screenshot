import AppKit
import SwiftUI

struct AnnotationCanvasView: NSViewRepresentable {
    let image: CGImage
    @ObservedObject var document: AnnotationDocument
    @ObservedObject var editorState: AnnotationEditorState
    let displaySize: CGSize?
    let coordinateScale: CGFloat
    let isInteractionEnabled: Bool
    var onTextInsertionRequested: ((CGPoint) -> Void)?
    var coordinateTransform: ((CGPoint) -> CGPoint)?
    var displayItems: [AnnotationItem]?

    init(
        image: CGImage,
        document: AnnotationDocument,
        editorState: AnnotationEditorState,
        displaySize: CGSize? = nil,
        coordinateScale: CGFloat = 1,
        isInteractionEnabled: Bool = true,
        onTextInsertionRequested: ((CGPoint) -> Void)? = nil,
        coordinateTransform: ((CGPoint) -> CGPoint)? = nil,
        displayItems: [AnnotationItem]? = nil
    ) {
        self.image = image
        self.document = document
        self.editorState = editorState
        self.displaySize = displaySize
        self.coordinateScale = coordinateScale
        self.isInteractionEnabled = isInteractionEnabled
        self.onTextInsertionRequested = onTextInsertionRequested
        self.coordinateTransform = coordinateTransform
        self.displayItems = displayItems
    }

    func makeNSView(context: Context) -> AnnotationCanvasNSView {
        AnnotationCanvasNSView(
            image: image,
            document: document,
            editorState: editorState,
            displaySize: displaySize,
            coordinateScale: coordinateScale,
            isInteractionEnabled: isInteractionEnabled,
            onTextInsertionRequested: onTextInsertionRequested,
            coordinateTransform: coordinateTransform,
            displayItems: displayItems
        )
    }

    func updateNSView(_ nsView: AnnotationCanvasNSView, context: Context) {
        nsView.image = image
        nsView.document = document
        nsView.editorState = editorState
        nsView.displaySize = displaySize
        nsView.coordinateScale = coordinateScale
        nsView.isInteractionEnabled = isInteractionEnabled
        nsView.onTextInsertionRequested = onTextInsertionRequested
        nsView.coordinateTransform = coordinateTransform
        nsView.displayItems = displayItems
        nsView.updateFrameIfNeeded()
        nsView.needsDisplay = true
    }
}

final class AnnotationCanvasNSView: NSView {
    var image: CGImage
    var document: AnnotationDocument
    var editorState: AnnotationEditorState
    var displaySize: CGSize?
    var coordinateScale: CGFloat
    var isInteractionEnabled: Bool
    var onTextInsertionRequested: ((CGPoint) -> Void)?
    var coordinateTransform: ((CGPoint) -> CGPoint)?
    var displayItems: [AnnotationItem]?

    private let renderer = AnnotationRenderer()
    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var currentPath: [CGPoint] = []

    init(
        image: CGImage,
        document: AnnotationDocument,
        editorState: AnnotationEditorState,
        displaySize: CGSize?,
        coordinateScale: CGFloat,
        isInteractionEnabled: Bool,
        onTextInsertionRequested: ((CGPoint) -> Void)?,
        coordinateTransform: ((CGPoint) -> CGPoint)?,
        displayItems: [AnnotationItem]?
    ) {
        self.image = image
        self.document = document
        self.editorState = editorState
        self.displaySize = displaySize
        self.coordinateScale = coordinateScale
        self.isInteractionEnabled = isInteractionEnabled
        self.onTextInsertionRequested = onTextInsertionRequested
        self.coordinateTransform = coordinateTransform
        self.displayItems = displayItems
        super.init(frame: CGRect(origin: .zero, size: displaySize ?? CGSize(width: image.width, height: image.height)))
        self.wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFrameIfNeeded() {
        let targetSize = displaySize ?? CGSize(width: image.width, height: image.height)
        if frame.size != targetSize {
            frame = CGRect(origin: frame.origin, size: targetSize)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let preview = editorState.previewItem(from: dragStart, to: dragCurrent, path: currentPath)
        let baseItems = displayItems ?? document.items
        let rendered = renderer.render(
            baseImage: image,
            items: preview.map { baseItems + [$0] } ?? baseItems
        )
        NSImage(cgImage: rendered, size: bounds.size).draw(in: bounds)
    }

    override func mouseDown(with event: NSEvent) {
        guard isInteractionEnabled else { return }
        let point = canvasPoint(from: event)
        switch editorState.selectedTool {
        case .text:
            onTextInsertionRequested?(point)
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
        guard isInteractionEnabled else { return }
        let point = canvasPoint(from: event)
        if editorState.selectedTool == .pen {
            currentPath.append(point)
        } else {
            dragCurrent = point
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isInteractionEnabled else { return }
        let point = canvasPoint(from: event)
        switch editorState.selectedTool {
        case .pen:
            currentPath.append(point)
            editorState.commitPath(currentPath.map(transformedPoint))
        case .text:
            break
        default:
            if let dragStart {
                editorState.commitDrag(from: transformedPoint(dragStart), to: transformedPoint(point))
            }
        }

        dragStart = nil
        dragCurrent = nil
        currentPath = []
        needsDisplay = true
    }

    private func canvasPoint(from event: NSEvent) -> CGPoint {
        let point = convert(event.locationInWindow, from: nil)
        return CGPoint(x: point.x * coordinateScale, y: point.y * coordinateScale)
    }

    private func transformedPoint(_ point: CGPoint) -> CGPoint {
        return coordinateTransform?(point) ?? point
    }
}
