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

    public init(preferences: MacShotPreferences) {
        self.preferences = preferences
    }

    @discardableResult
    public func start() -> Bool {
        guard state == .idle else { return false }
        state = .running
        return true
    }

    @discardableResult
    public func cancel() -> Bool {
        guard state == .running else { return false }
        state = .cancelled
        return true
    }

    @discardableResult
    public func complete(with image: NSImage, capturedAt: Date = Date()) -> Bool {
        guard state == .running else { return false }
        result = MacShotCaptureResult(image: image, capturedAt: capturedAt)
        state = .completed
        return true
    }
}
