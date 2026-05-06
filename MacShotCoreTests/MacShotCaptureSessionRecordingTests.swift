import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionRecordingTests: XCTestCase {
    func testStartRecordingDelegatesToRecordingEngineAndCompletesWithURL() {
        let engine = SpyRecordingEngine()
        let expectedURL = URL(fileURLWithPath: "/tmp/ScreenshotTool-recording.mp4")
        var completedResult: MacShotCaptureResult?
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { completedResult = $0 },
            recordingEngineFactory: { engine }
        )

        XCTAssertTrue(session.start())
        let screen = NSScreen.main ?? NSScreen.screens[0]
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 20, y: 30, width: 400, height: 240),
            screen: screen
        )

        XCTAssertEqual(engine.startedRect, NSRect(x: 20, y: 30, width: 400, height: 240))
        XCTAssertEqual(engine.startedScreen, screen)
        XCTAssertEqual(session.state, MacShotCaptureSession.State.recording)

        engine.completion?(expectedURL, nil)

        XCTAssertEqual(session.state, MacShotCaptureSession.State.completed)
        XCTAssertEqual(completedResult?.recordingURL, expectedURL)
        XCTAssertNil(completedResult?.image)
    }

    func testStopRecordingDelegatesToActiveRecordingEngine() {
        let engine = SpyRecordingEngine()
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            recordingEngineFactory: { engine }
        )
        let screen = NSScreen.main ?? NSScreen.screens[0]

        XCTAssertTrue(session.start())
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 1, y: 2, width: 120, height: 80),
            screen: screen
        )
        session.overlayDidRequestStopRecording(OverlayWindowController(screen: screen))

        XCTAssertEqual(engine.stopCount, 1)
    }

    func testCancelWhileRecordingIgnoresLaterEngineCompletion() {
        let engine = SpyRecordingEngine()
        let expectedURL = URL(fileURLWithPath: "/tmp/ScreenshotTool-cancelled-recording.mp4")
        var completionCount = 0
        var cancelCount = 0
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { _ in completionCount += 1 },
            onCancel: { cancelCount += 1 },
            recordingEngineFactory: { engine }
        )
        let screen = NSScreen.main ?? NSScreen.screens[0]

        XCTAssertTrue(session.start())
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 1, y: 2, width: 120, height: 80),
            screen: screen
        )
        XCTAssertTrue(session.cancel())
        engine.completion?(expectedURL, nil)

        XCTAssertEqual(session.state, MacShotCaptureSession.State.cancelled)
        XCTAssertEqual(cancelCount, 1)
        XCTAssertEqual(completionCount, 0)
    }
}

@MainActor
private final class SpyRecordingEngine: MacShotRecordingEngine {
    var completion: RecordingCompletion?
    var startedRect: NSRect?
    var startedScreen: NSScreen?
    var stopCount = 0

    func startRecording(
        rect: NSRect,
        screen: NSScreen,
        excludeWindowNumbers: [CGWindowID],
        completion: @escaping RecordingCompletion
    ) {
        startedRect = rect
        startedScreen = screen
        self.completion = completion
    }

    func stopRecording() {
        stopCount += 1
    }
}
