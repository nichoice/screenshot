import Foundation

@MainActor
final class CaptureCoordinator: ObservableObject {
    private let screenCaptureService: ScreenCaptureService

    @Published private(set) var isCapturing = false
    @Published private(set) var currentSelection: CaptureSelection?
    @Published private(set) var lastResult: CaptureResult?

    init(screenCaptureService: ScreenCaptureService) {
        self.screenCaptureService = screenCaptureService
    }

    func beginCapture() {
        isCapturing = true
        currentSelection = nil
    }

    func updateSelection(start: CGPoint, end: CGPoint) {
        currentSelection = CaptureSelection(start: start, end: end)
    }

    func cancelCapture() {
        isCapturing = false
        currentSelection = nil
    }

    func completeSelection() async throws {
        guard let selection = currentSelection else {
            return
        }

        let rect = selection.normalizedRect
        let image = try screenCaptureService.capture(rect: rect)
        let result = CaptureResult(image: image, selectionRect: rect, capturedAt: Date())

        lastResult = result
        currentSelection = nil
        isCapturing = false
    }
}
