import XCTest
@testable import ScreenshotTool

final class DefaultPermissionsServiceTests: XCTestCase {
    func testCurrentSnapshotReportsDeniedWhenSystemChecksReturnFalse() {
        let service = DefaultPermissionsService(
            screenCaptureAccessCheck: { false },
            accessibilityTrustCheck: { false }
        )

        let snapshot = service.currentSnapshot()

        XCTAssertEqual(snapshot.screenRecording, .denied)
        XCTAssertEqual(snapshot.accessibility, .denied)
    }

    func testCurrentSnapshotReportsGrantedWhenSystemChecksReturnTrue() {
        let service = DefaultPermissionsService(
            screenCaptureAccessCheck: { true },
            accessibilityTrustCheck: { true }
        )

        let snapshot = service.currentSnapshot()

        XCTAssertEqual(snapshot.screenRecording, .granted)
        XCTAssertEqual(snapshot.accessibility, .granted)
    }

    func testRequestScreenRecordingAccessSkipsPromptWhenAlreadyGranted() {
        var didRequestAccess = false
        let service = DefaultPermissionsService(
            screenCaptureAccessCheck: { true },
            screenCaptureAccessRequest: {
                didRequestAccess = true
                return true
            },
            accessibilityTrustCheck: { true }
        )

        let granted = service.requestScreenRecordingAccessIfNeeded()

        XCTAssertTrue(granted)
        XCTAssertFalse(didRequestAccess)
    }

    func testRequestScreenRecordingAccessPromptsWhenPreflightFails() {
        var requestCount = 0
        let service = DefaultPermissionsService(
            screenCaptureAccessCheck: { false },
            screenCaptureAccessRequest: {
                requestCount += 1
                return false
            },
            accessibilityTrustCheck: { true }
        )

        let granted = service.requestScreenRecordingAccessIfNeeded()

        XCTAssertFalse(granted)
        XCTAssertEqual(requestCount, 1)
    }
}
