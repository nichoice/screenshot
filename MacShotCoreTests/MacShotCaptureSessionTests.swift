import XCTest
import AppKit
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionTests: XCTestCase {
    func testSessionStartsOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)

        XCTAssertTrue(session.start())
        XCTAssertFalse(session.start())
        XCTAssertEqual(session.state, .running)
    }

    func testCancelMovesSessionToCancelledOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)
        _ = session.start()

        XCTAssertTrue(session.cancel())
        XCTAssertFalse(session.cancel())
        XCTAssertEqual(session.state, .cancelled)
    }

    func testSessionCompletesOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)
        _ = session.start()
        let image = NSImage(size: NSSize(width: 10, height: 8))

        XCTAssertTrue(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 456)))
        XCTAssertFalse(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 789)))
        XCTAssertEqual(session.state, .completed)
    }

    func testSessionDismissesOverlaysBeforeCompletionHandler() {
        var didDismissOverlays = false
        var completionObservedDismissedOverlays = false
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { _ in
                completionObservedDismissedOverlays = didDismissOverlays
            },
            onDismissOverlays: {
                didDismissOverlays = true
            }
        )
        _ = session.start()
        let image = NSImage(size: NSSize(width: 10, height: 8))

        XCTAssertTrue(session.complete(with: image))
        XCTAssertTrue(didDismissOverlays)
        XCTAssertTrue(completionObservedDismissedOverlays)
    }

    func testEngineStoresCompletionHandlerUntilSessionCompletes() {
        let engine = MacShotCaptureEngine(presentsOverlay: false)
        var received: MacShotCaptureResult?

        XCTAssertTrue(engine.startCapture(preferences: .defaults) { result in
            received = result
        } onCancel: {})

        let image = NSImage(size: NSSize(width: 10, height: 8))
        engine.completeForTesting(image: image, capturedAt: Date(timeIntervalSince1970: 321))

        XCTAssertEqual(received?.capturedAt, Date(timeIntervalSince1970: 321))
        XCTAssertFalse(engine.isCapturing)
    }
}
