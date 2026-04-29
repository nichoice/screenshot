import XCTest
import AppKit
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionTests: XCTestCase {
    func testSessionStartsOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults)

        XCTAssertTrue(session.start())
        XCTAssertFalse(session.start())
        XCTAssertEqual(session.state, .running)
    }

    func testCancelMovesSessionToCancelledOnce() {
        let session = MacShotCaptureSession(preferences: .defaults)
        _ = session.start()

        XCTAssertTrue(session.cancel())
        XCTAssertFalse(session.cancel())
        XCTAssertEqual(session.state, .cancelled)
    }

    func testSessionCompletesOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults)
        _ = session.start()
        let image = NSImage(size: NSSize(width: 10, height: 8))

        XCTAssertTrue(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 456)))
        XCTAssertFalse(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 789)))
        XCTAssertEqual(session.state, .completed)
    }
}
