import AppKit
import Foundation

@MainActor
public final class MacShotCaptureSession {
    public enum State: Equatable {
        case idle
        case running
        case recording
        case cancelled
        case completed
    }

    public private(set) var state: State = .idle
    public private(set) var result: MacShotCaptureResult?
    public let preferences: MacShotPreferences
    private let presentsOverlay: Bool
    private let onComplete: ((MacShotCaptureResult) -> Void)?
    private let onCancel: (() -> Void)?
    private let onDismissOverlays: (() -> Void)?
    private let recordingEngineFactory: @MainActor () -> MacShotRecordingEngine
    private let recordingHUDFactory: @MainActor () -> RecordingHUDPresenting
    private let recordingRegionOverlayFactory: @MainActor () -> RecordingRegionOverlayPresenting
    private var overlayControllers: [OverlayWindowController] = []
    private var recordingEngine: MacShotRecordingEngine?
    private var recordingHUDPanel: RecordingHUDPresenting?
    private var recordingRegionOverlay: RecordingRegionOverlayPresenting?

    public convenience init(preferences: MacShotPreferences) {
        self.init(preferences: preferences, presentsOverlay: true)
    }

    init(
        preferences: MacShotPreferences,
        presentsOverlay: Bool,
        onComplete: ((MacShotCaptureResult) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onDismissOverlays: (() -> Void)? = nil,
        recordingEngineFactory: @escaping @MainActor () -> MacShotRecordingEngine = {
            ScreenCaptureKitRecordingEngine()
        },
        recordingHUDFactory: @escaping @MainActor () -> RecordingHUDPresenting = {
            RecordingHUDPanel()
        },
        recordingRegionOverlayFactory: @escaping @MainActor () -> RecordingRegionOverlayPresenting = {
            RecordingRegionOverlayPanel()
        }
    ) {
        self.preferences = preferences
        self.presentsOverlay = presentsOverlay
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onDismissOverlays = onDismissOverlays
        self.recordingEngineFactory = recordingEngineFactory
        self.recordingHUDFactory = recordingHUDFactory
        self.recordingRegionOverlayFactory = recordingRegionOverlayFactory
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
        guard state == .running || state == .recording else { return false }
        recordingEngine?.stopRecording()
        recordingEngine = nil
        closeRecordingChrome()
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
        dismissOverlayControllers()
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
        onDismissOverlays?()
        overlayControllers.forEach { $0.dismiss() }
        overlayControllers.removeAll()
    }

    private func closeRecordingHUD() {
        recordingHUDPanel?.close()
        recordingHUDPanel = nil
    }

    private func closeRecordingRegionOverlay() {
        recordingRegionOverlay?.close()
        recordingRegionOverlay = nil
    }

    private func closeRecordingChrome() {
        closeRecordingHUD()
        closeRecordingRegionOverlay()
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
    }

    func overlayDidRequestPin(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
    }

    func overlayDidRequestOCR(_ controller: OverlayWindowController, text: String, image: NSImage?) {
        if let image {
            _ = complete(with: image)
        } else {
            _ = cancel()
        }
    }

    func overlayDidRequestUpload(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
    }

    func overlayDidRequestStartRecording(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {
        guard state == .running else { return }

        let engine = recordingEngineFactory()
        recordingEngine = engine
        state = .recording

        let hud = recordingHUDFactory()
        hud.onStopRecording = { [weak self] in
            self?.recordingEngine?.stopRecording()
            self?.closeRecordingChrome()
        }
        hud.show(relativeTo: rect, screen: screen)
        recordingHUDPanel = hud

        let regionOverlay = recordingRegionOverlayFactory()
        regionOverlay.show(relativeTo: rect, screen: screen)
        recordingRegionOverlay = regionOverlay

        let excludedWindowNumbers = overlayControllers.map(\.windowNumber)
            + [hud.excludedWindowNumber, regionOverlay.excludedWindowNumber]
        dismissOverlayControllers()

        engine.startRecording(
            rect: rect,
            screen: screen,
            excludeWindowNumbers: excludedWindowNumbers
        ) { [weak self] url, _ in
            guard let self else { return }
            guard self.state == .recording else { return }
            self.recordingEngine = nil
            self.closeRecordingChrome()
            guard let url else {
                self.state = .cancelled
                self.onCancel?()
                return
            }

            let captureResult = MacShotCaptureResult(recordingURL: url)
            self.result = captureResult
            self.state = .completed
            self.onComplete?(captureResult)
        }
    }

    func overlayDidRequestStopRecording(_ controller: OverlayWindowController) {
        recordingEngine?.stopRecording()
        closeRecordingChrome()
    }
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
