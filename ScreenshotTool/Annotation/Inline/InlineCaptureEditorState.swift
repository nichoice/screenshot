import CoreGraphics
import Foundation

struct InlineTextDraft: Equatable {
    var text: String
    let globalPoint: CGPoint
}

struct InlineFeedbackBanner: Equatable, Identifiable {
    let id = UUID()
    let message: String
}

struct InlineBusyToken: Equatable {
    fileprivate let id = UUID()
}

enum InlineSelectionHandle: CaseIterable {
    case topLeading
    case top
    case topTrailing
    case leading
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing
}

@MainActor
final class InlineCaptureEditorState: ObservableObject {
    let result: CaptureResult
    let screenFrame: CGRect
    let document: AnnotationDocument
    let editorState: AnnotationEditorState

    @Published var selectionRect: CGRect
    @Published var isSelectionModeActive = true
    @Published var textDraft: InlineTextDraft?
    @Published var lastRecognizedText: String?
    @Published var feedbackBanner: InlineFeedbackBanner?
    @Published private var busyActions: [InlineAnnotationToolbarItem: InlineBusyToken] = [:]

    private let minimumSelectionSize: CGFloat = 48

    init(result: CaptureResult, screenFrame: CGRect, document: AnnotationDocument) {
        self.result = result
        self.screenFrame = screenFrame
        self.document = document
        self.editorState = AnnotationEditorState(document: document)
        self.selectionRect = result.selectionRect.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    }

    var availableRect: CGRect {
        CGRect(origin: .zero, size: screenFrame.size)
    }

    var globalSelectionRect: CGRect {
        selectionRect.offsetBy(dx: screenFrame.minX, dy: screenFrame.minY)
    }

    var toolbarPlacement: CGRect {
        FloatingToolbarPlacement.resolve(
            selectionRect: selectionRect,
            availableRect: availableRect,
            toolbarSize: CGSize(width: 720, height: 56)
        )
    }

    var localAnnotationItems: [AnnotationItem] {
        document.items.map { $0.offsetBy(dx: -selectionRect.minX, dy: -selectionRect.minY) }
    }

    func currentCroppedImage() -> CGImage? {
        CaptureImageCropper.crop(
            image: result.fullImage,
            imageBounds: availableRect,
            selectionRect: selectionRect
        )
    }

    func finalizedResult() -> CaptureResult? {
        let renderedFullImage = AnnotationRenderer().render(baseImage: result.fullImage, items: document.items)
        guard let cropped = CaptureImageCropper.crop(
            image: renderedFullImage,
            imageBounds: availableRect,
            selectionRect: selectionRect
        ) else {
            return nil
        }

        return CaptureResult(
            fullImage: renderedFullImage,
            image: cropped,
            selectionRect: globalSelectionRect,
            capturedAt: result.capturedAt
        )
    }

    func localPointToGlobal(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x + selectionRect.minX, y: point.y + selectionRect.minY)
    }

    func localPathToGlobal(_ points: [CGPoint]) -> [CGPoint] {
        points.map(localPointToGlobal)
    }

    func activateTool(_ tool: AnnotationTool) {
        if !isSelectionModeActive, editorState.selectedTool == tool {
            isSelectionModeActive = true
            cancelTextEntry()
            return
        }

        editorState.selectedTool = tool
        isSelectionModeActive = false
        if tool != .text {
            cancelTextEntry()
        }
    }

    func moveSelection(translation: CGSize, initialRect: CGRect) {
        cancelTextEntry()
        let width = initialRect.width
        let height = initialRect.height
        let proposedX = initialRect.minX + translation.width
        let proposedY = initialRect.minY + translation.height

        let clampedX = min(max(availableRect.minX, proposedX), availableRect.maxX - width)
        let clampedY = min(max(availableRect.minY, proposedY), availableRect.maxY - height)

        selectionRect = CGRect(x: clampedX, y: clampedY, width: width, height: height)
    }

    func beginTextEntry(atLocalPoint point: CGPoint) {
        guard editorState.selectedTool == .text else { return }
        textDraft = InlineTextDraft(text: "", globalPoint: localPointToGlobal(point))
    }

    func updateTextDraft(_ text: String) {
        guard var draft = textDraft else { return }
        draft.text = text
        textDraft = draft
    }

    func commitTextEntry() {
        guard let draft = textDraft else { return }
        let value = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { textDraft = nil }
        guard !value.isEmpty else { return }
        editorState.textValue = value
        editorState.commitClick(at: draft.globalPoint)
    }

    func cancelTextEntry() {
        textDraft = nil
    }

    func insertEmoji(_ emoji: String) {
        let value = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        let point = CGPoint(x: selectionRect.midX, y: selectionRect.midY)
        let previousTool = editorState.selectedTool
        let previousFontSize = editorState.fontSize
        let previousTextValue = editorState.textValue
        editorState.selectedTool = .text
        editorState.textValue = value
        editorState.fontSize = max(previousFontSize, 24)
        editorState.commitClick(at: point)
        editorState.textValue = previousTextValue
        editorState.selectedTool = previousTool
        editorState.fontSize = previousFontSize
    }

    func presentRecognizedText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastRecognizedText = nil
            showFeedback("未识别到文字")
            return
        }

        lastRecognizedText = trimmed
        let lineCount = trimmed.split(whereSeparator: \.isNewline).count
        showFeedback("已复制 \(max(1, lineCount)) 行文字")
    }

    func showFeedback(_ message: String) {
        feedbackBanner = InlineFeedbackBanner(message: message)
    }

    func dismissFeedbackBanner(id: UUID) {
        guard feedbackBanner?.id == id else { return }
        feedbackBanner = nil
    }

    func beginBusyAction(_ item: InlineAnnotationToolbarItem) -> InlineBusyToken {
        let token = InlineBusyToken()
        busyActions[item] = token
        return token
    }

    func endBusyAction(_ item: InlineAnnotationToolbarItem, token: InlineBusyToken) {
        guard busyActions[item] == token else { return }
        busyActions[item] = nil
    }

    func isBusy(_ item: InlineAnnotationToolbarItem) -> Bool {
        busyActions[item] != nil
    }

    func resizeSelection(using handle: InlineSelectionHandle, translation: CGSize, initialRect: CGRect) {
        cancelTextEntry()
        var minX = initialRect.minX
        var maxX = initialRect.maxX
        var minY = initialRect.minY
        var maxY = initialRect.maxY

        switch handle {
        case .topLeading:
            minX += translation.width
            maxY += translation.height
        case .top:
            maxY += translation.height
        case .topTrailing:
            maxX += translation.width
            maxY += translation.height
        case .leading:
            minX += translation.width
        case .trailing:
            maxX += translation.width
        case .bottomLeading:
            minX += translation.width
            minY += translation.height
        case .bottom:
            minY += translation.height
        case .bottomTrailing:
            maxX += translation.width
            minY += translation.height
        }

        if maxX - minX < minimumSelectionSize {
            switch handle {
            case .topLeading, .leading, .bottomLeading:
                minX = maxX - minimumSelectionSize
            default:
                maxX = minX + minimumSelectionSize
            }
        }

        if maxY - minY < minimumSelectionSize {
            switch handle {
            case .bottomLeading, .bottom, .bottomTrailing:
                minY = maxY - minimumSelectionSize
            default:
                maxY = minY + minimumSelectionSize
            }
        }

        minX = max(availableRect.minX, minX)
        minY = max(availableRect.minY, minY)
        maxX = min(availableRect.maxX, maxX)
        maxY = min(availableRect.maxY, maxY)

        selectionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func handleFrame(for handle: InlineSelectionHandle, canvasSize: CGSize) -> CGRect {
        let point: CGPoint
        switch handle {
        case .topLeading:
            point = CGPoint(x: 0, y: canvasSize.height)
        case .top:
            point = CGPoint(x: canvasSize.width / 2, y: canvasSize.height)
        case .topTrailing:
            point = CGPoint(x: canvasSize.width, y: canvasSize.height)
        case .leading:
            point = CGPoint(x: 0, y: canvasSize.height / 2)
        case .trailing:
            point = CGPoint(x: canvasSize.width, y: canvasSize.height / 2)
        case .bottomLeading:
            point = CGPoint(x: 0, y: 0)
        case .bottom:
            point = CGPoint(x: canvasSize.width / 2, y: 0)
        case .bottomTrailing:
            point = CGPoint(x: canvasSize.width, y: 0)
        }

        return CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
    }
}
