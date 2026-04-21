import SwiftUI

struct InlineAnnotationEditorView: View {
    @ObservedObject var state: InlineCaptureEditorState
    @FocusState private var isTextEditorFocused: Bool
    @State private var feedbackDismissTask: Task<Void, Never>?
    let onCopy: () -> Void
    let onSave: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onOCR: () -> Void
    let onShare: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private let palette = ["#FF3B30", "#FF9500", "#FFD60A", "#34C759", "#0A84FF", "#FFFFFF", "#111111"]
    @State private var selectionDragOrigin: CGRect = .zero

    var body: some View {
        let croppedImage = state.currentCroppedImage() ?? state.result.image
        let displaySize = fittedCanvasSize
        let scale = displaySize.width > 0 ? CGFloat(croppedImage.width) / displaySize.width : 1

        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.46)
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: state.selectionRect.width, height: state.selectionRect.height)
                        .position(x: state.selectionRect.midX, y: state.selectionRect.midY)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()

            AnnotationCanvasView(
                image: croppedImage,
                document: state.document,
                editorState: state.editorState,
                displaySize: displaySize,
                coordinateScale: scale,
                isInteractionEnabled: !state.isSelectionModeActive,
                onTextInsertionRequested: { point in
                    state.beginTextEntry(atLocalPoint: point)
                    isTextEditorFocused = true
                },
                coordinateTransform: state.localPointToGlobal,
                displayItems: state.localAnnotationItems
            )
            .frame(width: displaySize.width, height: displaySize.height)
            .position(x: state.selectionRect.midX, y: state.selectionRect.midY)
            .contentShape(Rectangle())
            .gesture(selectionMoveGesture)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.green.opacity(0.95), lineWidth: 2)
            )
            .overlay(selectionHandles, alignment: .topLeading)

            Text("\(Int(state.selectionRect.width.rounded())) x \(Int(state.selectionRect.height.rounded()))")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .position(
                    x: state.selectionRect.minX + 54,
                    y: max(18, state.selectionRect.minY - 18)
                )

            if let textDraft = state.textDraft {
                inlineTextEditor(draft: textDraft)
            }

            if let feedbackBanner = state.feedbackBanner {
                feedbackToast(feedbackBanner.message)
            }

            InlineToolbarChrome(
                state: state,
                editorState: state.editorState,
                palette: palette,
                onCopy: onCopy,
                onSave: onSave,
                onPin: onPin,
                onEdit: onEdit,
                onOCR: onOCR,
                onShare: onShare,
                onCancel: onCancel,
                onConfirm: onConfirm
            )
            .position(x: state.toolbarPlacement.midX, y: state.toolbarPlacement.midY)
        }
        .frame(width: state.availableRect.width, height: state.availableRect.height, alignment: .topLeading)
        .ignoresSafeArea()
        .onChange(of: state.textDraft != nil) { _, isPresenting in
            isTextEditorFocused = isPresenting
        }
        .onChange(of: state.feedbackBanner?.id) { _, bannerID in
            feedbackDismissTask?.cancel()
            guard let bannerID else { return }

            feedbackDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.22)) {
                    state.dismissFeedbackBanner(id: bannerID)
                }
            }
        }
    }

    private var fittedCanvasSize: CGSize {
        let width = state.selectionRect.width
        let height = state.selectionRect.height
        guard state.result.fullImage.width > 0, state.result.fullImage.height > 0, width > 0, height > 0 else {
            return CGSize(width: state.selectionRect.width, height: state.selectionRect.height)
        }
        return CGSize(width: width, height: height)
    }

    private var selectionHandles: some View {
        GeometryReader { proxy in
            ForEach(Array(InlineSelectionHandle.allCases.enumerated()), id: \.offset) { _, handle in
                let frame = state.handleFrame(for: handle, canvasSize: proxy.size)
                SelectionHandleView(
                    frame: frame,
                    handle: handle,
                    state: state
                )
            }
        }
    }

    private var selectionMoveGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard state.isSelectionModeActive else { return }
                if selectionDragOrigin == .zero {
                    selectionDragOrigin = state.selectionRect
                }
                state.moveSelection(translation: value.translation, initialRect: selectionDragOrigin)
            }
            .onEnded { _ in
                selectionDragOrigin = .zero
            }
    }

    @ViewBuilder
    private func inlineTextEditor(draft: InlineTextDraft) -> some View {
        let localPoint = CGPoint(
            x: draft.globalPoint.x - state.selectionRect.minX,
            y: draft.globalPoint.y - state.selectionRect.minY
        )
        TextField("输入文字", text: Binding(
            get: { state.textDraft?.text ?? "" },
            set: { state.updateTextDraft($0) }
        ))
        .textFieldStyle(.plain)
        .font(.system(size: max(14, state.editorState.fontSize), weight: .medium))
        .foregroundStyle(Color(nsColor: AnnotationRenderer.nsColor(state.editorState.strokeColorHex)))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(width: 180, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
        .position(
            x: state.selectionRect.minX + min(localPoint.x + 90, max(90, state.selectionRect.width - 90)),
            y: state.selectionRect.minY + max(18, min(localPoint.y, state.selectionRect.height - 18))
        )
        .focused($isTextEditorFocused)
        .onSubmit {
            state.commitTextEntry()
        }
        .onExitCommand {
            state.cancelTextEntry()
        }
    }

    private func feedbackToast(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.78), in: Capsule())
            .position(x: state.selectionRect.midX, y: max(28, state.selectionRect.minY - 44))
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

private struct SelectionHandleView: View {
    let frame: CGRect
    let handle: InlineSelectionHandle
    @ObservedObject var state: InlineCaptureEditorState
    @State private var initialRect: CGRect = .zero

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(Color.green.opacity(0.98))
            .frame(width: 8, height: 8)
            .position(x: frame.midX, y: frame.midY)
            .contentShape(Rectangle().path(in: frame))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard state.isSelectionModeActive else { return }
                        if initialRect == .zero {
                            initialRect = state.selectionRect
                        }
                        state.resizeSelection(using: handle, translation: value.translation, initialRect: initialRect)
                    }
                    .onEnded { _ in
                        initialRect = .zero
                    }
            )
    }
}

private struct InlineToolbarChrome: View {
    @ObservedObject var state: InlineCaptureEditorState
    @ObservedObject var editorState: AnnotationEditorState
    let palette: [String]
    let onCopy: () -> Void
    let onSave: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onOCR: () -> Void
    let onShare: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(InlineAnnotationToolbarModel.groups.enumerated()), id: \.offset) { index, group in
                toolbarGroup(group)

                if index < InlineAnnotationToolbarModel.groups.count - 1 {
                    Divider()
                        .frame(height: 22)
                        .overlay(Color.white.opacity(0.16))
                }
            }

            Divider()
                .frame(height: 22)
                .overlay(Color.white.opacity(0.16))

            HStack(spacing: 6) {
                ForEach(palette, id: \.self) { hex in
                    colorSwatch(hex)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 52)
        .background(toolbarBackground)
        .overlay(toolbarOutline)
        .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 10)
    }

    private var toolbarBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
    }

    private var toolbarOutline: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.34), Color.white.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }

    private func toolbarGroup(_ items: [InlineAnnotationToolbarItem]) -> some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                toolbarButton(for: item)
            }
        }
    }

    @ViewBuilder
    private func toolbarButton(for item: InlineAnnotationToolbarItem) -> some View {
        switch item {
        case .rectangle:
            toolButton(symbol: "square", isSelected: editorState.selectedTool == .rectangle) {
                state.activateTool(.rectangle)
            }
        case .ellipse:
            toolButton(symbol: "circle", isSelected: editorState.selectedTool == .ellipse) {
                state.activateTool(.ellipse)
            }
        case .emoji:
            toolButton(symbol: "face.smiling") {
                state.insertEmoji("🙂")
            }
        case .arrow:
            toolButton(symbol: "arrow.up.right", isSelected: editorState.selectedTool == .arrow) {
                state.activateTool(.arrow)
            }
        case .pen:
            toolButton(symbol: "pencil", isSelected: editorState.selectedTool == .pen) {
                state.activateTool(.pen)
            }
        case .mosaic:
            toolButton(symbol: "square.grid.3x3", isSelected: editorState.selectedTool == .blur) {
                state.activateTool(.blur)
            }
        case .text:
            toolButton(symbol: "character.textbox", isSelected: editorState.selectedTool == .text) {
                state.activateTool(.text)
            }
        case .ocr:
            toolButton(symbol: "text.viewfinder") {
                onOCR()
            }
        case .undo:
            toolButton(symbol: "arrow.uturn.backward") {
                editorState.undo()
            }
        case .save:
            toolButton(symbol: "square.and.arrow.down") {
                onSave()
            }
        case .pin:
            toolButton(symbol: "pin") {
                onPin()
            }
        case .edit:
            toolButton(symbol: "slider.horizontal.3") {
                onEdit()
            }
        case .share:
            toolButton(symbol: "square.and.arrow.up") {
                onShare()
            }
        case .cancel:
            toolButton(symbol: "xmark", tint: .red) {
                onCancel()
            }
        case .confirm:
            toolButton(symbol: "checkmark", tint: .green) {
                onConfirm()
            }
        }
    }

    private func toolButton(symbol: String, isSelected: Bool = false, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        let isBusy = busyItem(for: symbol).map(state.isBusy) ?? false

        return Button(action: action) {
            ZStack {
                if isBusy {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.62)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint ?? .primary.opacity(isSelected ? 1 : 0.94))
                }
            }
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.16) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.22) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(InlineToolbarButtonStyle())
        .disabled(isBusy)
        .scaleEffect(isBusy ? 0.96 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: isBusy)
    }

    private func busyItem(for symbol: String) -> InlineAnnotationToolbarItem? {
        switch symbol {
        case "text.viewfinder":
            return .ocr
        case "square.and.arrow.down":
            return .save
        case "square.and.arrow.up":
            return .share
        default:
            return nil
        }
    }

    private func colorSwatch(_ hex: String) -> some View {
        Button {
            editorState.strokeColorHex = hex
        } label: {
            Circle()
                .fill(Color(nsColor: AnnotationRenderer.nsColor(hex)))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .strokeBorder(editorState.strokeColorHex == hex ? Color.white.opacity(0.92) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct InlineToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
