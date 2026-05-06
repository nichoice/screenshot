import AppKit
import Foundation

@MainActor
public final class MacShotCaptureEngine {
    private var activeSession: MacShotCaptureSession?
    private var onComplete: ((MacShotCaptureResult) -> Void)?
    private var onCancel: (() -> Void)?
    private let presentsOverlay: Bool

    public convenience init() {
        self.init(presentsOverlay: true)
    }

    init(presentsOverlay: Bool) {
        self.presentsOverlay = presentsOverlay
    }

    public var isCapturing: Bool {
        activeSession?.state == .running || activeSession?.state == .recording
    }

    @discardableResult
    public func startCapture(
        preferences: MacShotPreferences,
        onComplete: @escaping (MacShotCaptureResult) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) -> Bool {
        guard activeSession?.state != .running && activeSession?.state != .recording else { return false }
        self.onComplete = onComplete
        self.onCancel = onCancel
        let session = MacShotCaptureSession(
            preferences: preferences,
            presentsOverlay: presentsOverlay,
            onComplete: { [weak self] result in
                self?.finishCapture(with: result)
            },
            onCancel: { [weak self] in
                self?.finishCancellation()
            }
        )
        activeSession = session
        return session.start()
    }

    public func cancelCapture() {
        guard let session = activeSession else { return }
        _ = session.cancel()
    }

    private func finishCapture(with result: MacShotCaptureResult) {
        activeSession = nil
        onComplete?(result)
        onComplete = nil
        onCancel = nil
    }

    private func finishCancellation() {
        activeSession = nil
        onCancel?()
        onComplete = nil
        onCancel = nil
    }

    func completeForTesting(image: NSImage, capturedAt: Date) {
        guard let session = activeSession else { return }
        _ = session.complete(with: image, capturedAt: capturedAt)
    }
}
