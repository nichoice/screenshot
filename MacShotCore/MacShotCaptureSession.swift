import AppKit
import Foundation

@MainActor
public final class MacShotCaptureSession {
    public enum State: Equatable {
        case idle
        case running
        case cancelled
        case completed
    }

    public private(set) var state: State = .idle
    public private(set) var result: MacShotCaptureResult?
    public let preferences: MacShotPreferences
    private let presentsOverlay: Bool
    private let onComplete: ((MacShotCaptureResult) -> Void)?
    private let onCancel: (() -> Void)?
    private var overlayControllers: [OverlayWindowController] = []

    public convenience init(preferences: MacShotPreferences) {
        self.init(preferences: preferences, presentsOverlay: true)
    }

    init(
        preferences: MacShotPreferences,
        presentsOverlay: Bool,
        onComplete: ((MacShotCaptureResult) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.preferences = preferences
        self.presentsOverlay = presentsOverlay
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    @discardableResult
    public func start() -> Bool {
        guard state == .idle else { return false }
        MacShotPreferencesAdapter().apply(preferences)
        state = .running
        if presentsOverlay {
            startImportedOverlayControllers()
        }
        return true
    }

    @discardableResult
    public func cancel() -> Bool {
        guard state == .running else { return false }
        dismissOverlayControllers()
        state = .cancelled
        onCancel?()
        return true
    }

    @discardableResult
    public func complete(with image: NSImage, capturedAt: Date = Date()) -> Bool {
        guard state == .running else { return false }
        let captureResult = MacShotCaptureResult(image: image, capturedAt: capturedAt)
        result = captureResult
        state = .completed
        onComplete?(captureResult)
        return true
    }

    private func startImportedOverlayControllers() {
        for screen in NSScreen.screens {
            let controller = OverlayWindowController(screen: screen)
            controller.overlayDelegate = self
            controller.showOverlay()
            overlayControllers.append(controller)
        }

        let excludedWindowNumbers = overlayControllers.map(\.windowNumber)
        ScreenCaptureManager.captureAllScreens(excludingWindowNumbers: excludedWindowNumbers) { [weak self] captures in
            guard let self else { return }
            if captures.isEmpty {
                _ = self.cancel()
                return
            }

            for capture in captures {
                self.overlayControllers.first(where: { $0.screen == capture.screen })?.setScreenshot(capture.image)
            }
        }
    }

    private func dismissOverlayControllers() {
        overlayControllers.forEach { $0.dismiss() }
        overlayControllers.removeAll()
    }
}

extension MacShotCaptureSession: OverlayWindowControllerDelegate {
    func overlayDidCancel(_ controller: OverlayWindowController) {
        _ = cancel()
    }

    func overlayDidConfirm(
        _ controller: OverlayWindowController,
        capturedImage: NSImage?,
        annotationData: CaptureAnnotationData?
    ) {
        guard let image = capturedImage else {
            _ = cancel()
            return
        }
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestPin(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestOCR(_ controller: OverlayWindowController, text: String, image: NSImage?) {
        if let image {
            _ = complete(with: image)
        } else {
            _ = cancel()
        }
        dismissOverlayControllers()
    }

    func overlayDidRequestUpload(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestStartRecording(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {}
    func overlayDidRequestStopRecording(_ controller: OverlayWindowController) {}
    func overlayDidRequestScrollCapture(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {}
    func overlayDidRequestStopScrollCapture(_ controller: OverlayWindowController) {}
    func overlayDidRequestToggleAutoScroll(_ controller: OverlayWindowController) {}
    func overlayDidRequestAccessibilityPermission(_ controller: OverlayWindowController) {}
    func overlayDidRequestInputMonitoringPermission(_ controller: OverlayWindowController) {}
    func overlayDidBeginSelection(_ controller: OverlayWindowController) {}
    func overlayDidChangeSelection(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayDidRemoteResizeSelection(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayDidFinishRemoteResize(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayCrossScreenImage(_ controller: OverlayWindowController) -> NSImage? { nil }
    func overlayDidChangeWindowSnapState(_ controller: OverlayWindowController) {}
}
