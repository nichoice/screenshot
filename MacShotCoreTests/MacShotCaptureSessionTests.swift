import XCTest
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
}
