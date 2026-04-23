import AppKit
import CoreGraphics
import Foundation

@MainActor
final class CaptureCoordinator: ObservableObject {
    private let screenCaptureService: ScreenCaptureService
    private let desktopRectProvider: @Sendable () -> CGRect
    private var fullDesktopTask: Task<PreparedFullCapture, Error>?

    @Published private(set) var isCapturing = false
    @Published private(set) var currentSelection: CaptureSelection?
    @Published private(set) var lastResult: CaptureResult?

    var onCaptureStarted: (() -> Void)?
    var onCaptureCancelled: (() -> Void)?
    var onCaptureCompleted: ((CaptureResult) -> Void)?

    init(
        screenCaptureService: ScreenCaptureService,
        desktopRectProvider: @escaping @Sendable () -> CGRect = {
            NSScreen.screens.reduce(into: CGRect.null) { partial, screen in
                partial = partial.union(screen.frame)
            }
        }
    ) {
        self.screenCaptureService = screenCaptureService
        self.desktopRectProvider = desktopRectProvider
    }

    func beginCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        currentSelection = nil
        onCaptureStarted?()
    }

    func prepareFullDesktopCaptureIfNeeded() {
        guard fullDesktopTask == nil else { return }

        let screenCaptureService = self.screenCaptureService
        let desktopRectProvider = self.desktopRectProvider
        fullDesktopTask = Task.detached(priority: .userInitiated) {
            let desktopRect = desktopRectProvider()
            let fullImage = try screenCaptureService.capture(rect: .infinite)
            return PreparedFullCapture(image: fullImage, bounds: desktopRect)
        }
    }

    func updateSelection(start: CGPoint, end: CGPoint) {
        currentSelection = CaptureSelection(start: start, end: end)
    }

    func cancelCapture() {
        isCapturing = false
        currentSelection = nil
        fullDesktopTask?.cancel()
        fullDesktopTask = nil
        onCaptureCancelled?()
    }

    func completeSelection() async throws {
        guard let selection = currentSelection else {
            cancelCapture()
            return
        }

        do {
            let rect = selection.normalizedRect
            let preparedCapture = try await preparedFullDesktopCapture()
            guard let image = CaptureImageCropper.crop(
                image: preparedCapture.image,
                imageBounds: preparedCapture.bounds,
                selectionRect: rect
            ) else {
                throw ScreenCaptureError.captureFailed
            }
            let fullImage = preparedCapture.image
            let result = CaptureResult(fullImage: fullImage, image: image, selectionRect: rect, capturedAt: Date())

            lastResult = result
            currentSelection = nil
            isCapturing = false
            fullDesktopTask = nil
            onCaptureCompleted?(result)
        } catch {
            currentSelection = nil
            isCapturing = false
            fullDesktopTask = nil
            throw error
        }
    }

    private func preparedFullDesktopCapture() async throws -> PreparedFullCapture {
        if let fullDesktopTask {
            return try await fullDesktopTask.value
        }

        let bounds = desktopRectProvider()
        let image = try screenCaptureService.capture(rect: .infinite)
        return PreparedFullCapture(image: image, bounds: bounds)
    }
}

private struct PreparedFullCapture: Sendable {
    let image: CGImage
    let bounds: CGRect
}
