import Foundation

@MainActor
public final class MacShotCaptureEngine {
    private var activeSession: MacShotCaptureSession?

    public init() {}

    public var isCapturing: Bool {
        activeSession?.state == .running
    }

    @discardableResult
    public func startCapture(preferences: MacShotPreferences) -> Bool {
        guard activeSession?.state != .running else { return false }
        let session = MacShotCaptureSession(preferences: preferences)
        activeSession = session
        return session.start()
    }

    public func cancelCapture() {
        _ = activeSession?.cancel()
        activeSession = nil
    }
}
