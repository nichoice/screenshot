import AppKit
import Foundation

public struct MacShotCaptureResult {
    public let image: NSImage
    public let capturedAt: Date

    public init(image: NSImage, capturedAt: Date) {
        self.image = image
        self.capturedAt = capturedAt
    }
}
