import SwiftUI

struct AnnotationEditorView: View {
    let image: CGImage
    @ObservedObject var document: AnnotationDocument
    @ObservedObject var editorState: AnnotationEditorState

    private let palette = ["#FF3B30", "#34C759", "#007AFF", "#FF9500", "#111111"]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Picker("Tool", selection: $editorState.selectedTool) {
                    ForEach(AnnotationTool.allCases, id: \.self) { tool in
                        Text(tool.rawValue.capitalized).tag(tool)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    ForEach(palette, id: \.self) { hex in
                        Button {
                            editorState.strokeColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(nsColor: AnnotationRenderer.nsColor(hex)))
                                .frame(width: 18, height: 18)
                                .overlay {
                                    if editorState.strokeColorHex == hex {
                                        Circle().stroke(Color.black.opacity(0.5), lineWidth: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Slider(value: $editorState.lineWidth, in: 1...12) {
                    Text("Width")
                }
                .frame(width: 140)

                if editorState.selectedTool == .text {
                    TextField("Text", text: $editorState.textValue)
                        .frame(width: 180)
                }

                Button("Undo") {
                    editorState.undo()
                }

                Button("Clear") {
                    editorState.clear()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            AnnotationCanvasView(
                image: image,
                document: document,
                editorState: editorState
            )
            .frame(minWidth: 800, minHeight: 600)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 900, minHeight: 680)
    }
}
