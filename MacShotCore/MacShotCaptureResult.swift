import AppKit
import Foundation

public struct MacShotCaptureResult {
    public let image: NSImage?
    public let recordingURL: URL?
    public let capturedAt: Date

    public init(image: NSImage, capturedAt: Date) {
        self.image = image
        self.recordingURL = nil
        self.capturedAt = capturedAt
    }

    public init(recordingURL: URL, capturedAt: Date = Date()) {
        self.image = nil
        self.recordingURL = recordingURL
        self.capturedAt = capturedAt
    }
}
