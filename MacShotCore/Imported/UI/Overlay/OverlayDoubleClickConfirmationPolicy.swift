import Foundation

struct OverlayDoubleClickConfirmationPolicy {
    var clickCount: Int
    var state: OverlayView.State
    var currentTool: AnnotationTool
    var isTextEditing: Bool
    var isRecording: Bool
    var isScrollCapturing: Bool
    var isPointInsideSelection: Bool

    var shouldRequestQuickSave: Bool {
        clickCount >= 2
            && state == .selected
            && currentTool != .text
            && !isTextEditing
            && !isRecording
            && !isScrollCapturing
            && isPointInsideSelection
    }
}
