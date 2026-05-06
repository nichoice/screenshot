import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionRecordingTests: XCTestCase {
    func testStartRecordingDelegatesToRecordingEngineAndCompletesWithURL() {
        let engine = SpyRecordingEngine()
        let regionOverlay = SpyRecordingRegionOverlay(windowNumber: 4242)
        let expectedURL = URL(fileURLWithPath: "/tmp/ScreenshotTool-recording.mp4")
        var completedResult: MacShotCaptureResult?
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { completedResult = $0 },
            recordingEngineFactory: { engine },
            recordingRegionOverlayFactory: { regionOverlay }
        )

        XCTAssertTrue(session.start())
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let recordingRect = NSRect(x: 20, y: 30, width: 400, height: 240)
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: recordingRect,
            screen: screen
        )

        XCTAssertEqual(engine.startedRect, recordingRect)
        XCTAssertEqual(engine.startedScreen, screen)
        XCTAssertEqual(regionOverlay.shownRect, recordingRect)
        XCTAssertEqual(regionOverlay.shownScreen, screen)
        XCTAssertTrue(engine.excludeWindowNumbers.contains(regionOverlay.excludedWindowNumber))
        XCTAssertEqual(session.state, MacShotCaptureSession.State.recording)

        engine.completion?(expectedURL, nil)

        XCTAssertEqual(session.state, MacShotCaptureSession.State.completed)
        XCTAssertEqual(completedResult?.recordingURL, expectedURL)
        XCTAssertNil(completedResult?.image)
        XCTAssertEqual(regionOverlay.closeCount, 1)
    }

    func testStopRecordingDelegatesToActiveRecordingEngine() {
        let engine = SpyRecordingEngine()
        let regionOverlay = SpyRecordingRegionOverlay(windowNumber: 5151)
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            recordingEngineFactory: { engine },
            recordingRegionOverlayFactory: { regionOverlay }
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
        XCTAssertEqual(regionOverlay.closeCount, 1)
    }

    func testHUDStopClosesRecordingChromeImmediately() {
        let engine = SpyRecordingEngine()
        let hud = SpyRecordingHUD(windowNumber: 7171)
        let regionOverlay = SpyRecordingRegionOverlay(windowNumber: 8181)
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            recordingEngineFactory: { engine },
            recordingHUDFactory: { hud },
            recordingRegionOverlayFactory: { regionOverlay }
        )
        let screen = NSScreen.main ?? NSScreen.screens[0]

        XCTAssertTrue(session.start())
        session.overlayDidRequestStartRecording(
            OverlayWindowController(screen: screen),
            rect: NSRect(x: 1, y: 2, width: 120, height: 80),
            screen: screen
        )
        hud.onStopRecording?()

        XCTAssertEqual(engine.stopCount, 1)
        XCTAssertEqual(hud.closeCount, 1)
        XCTAssertEqual(regionOverlay.closeCount, 1)
    }

    func testCancelWhileRecordingIgnoresLaterEngineCompletion() {
        let engine = SpyRecordingEngine()
        let regionOverlay = SpyRecordingRegionOverlay(windowNumber: 6161)
        let expectedURL = URL(fileURLWithPath: "/tmp/ScreenshotTool-cancelled-recording.mp4")
        var completionCount = 0
        var cancelCount = 0
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { _ in completionCount += 1 },
            onCancel: { cancelCount += 1 },
            recordingEngineFactory: { engine },
            recordingRegionOverlayFactory: { regionOverlay }
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
        XCTAssertEqual(regionOverlay.closeCount, 1)
    }
}

@MainActor
private final class SpyRecordingEngine: MacShotRecordingEngine {
    var completion: RecordingCompletion?
    var startedRect: NSRect?
    var startedScreen: NSScreen?
    var excludeWindowNumbers: [CGWindowID] = []
    var stopCount = 0

    func startRecording(
        rect: NSRect,
        screen: NSScreen,
        excludeWindowNumbers: [CGWindowID],
        completion: @escaping RecordingCompletion
    ) {
        startedRect = rect
        startedScreen = screen
        self.excludeWindowNumbers = excludeWindowNumbers
        self.completion = completion
    }

    func stopRecording() {
        stopCount += 1
    }
}

@MainActor
private final class SpyRecordingHUD: RecordingHUDPresenting {
    let excludedWindowNumber: CGWindowID
    var onStopRecording: (() -> Void)?
    private(set) var shownRect: NSRect?
    private(set) var shownScreen: NSScreen?
    private(set) var closeCount = 0

    init(windowNumber: CGWindowID) {
        self.excludedWindowNumber = windowNumber
    }

    func show(relativeTo screenRect: NSRect, screen: NSScreen) {
        shownRect = screenRect
        shownScreen = screen
    }

    func close() {
        closeCount += 1
    }
}

@MainActor
private final class SpyRecordingRegionOverlay: RecordingRegionOverlayPresenting {
    let excludedWindowNumber: CGWindowID
    private(set) var shownRect: NSRect?
    private(set) var shownScreen: NSScreen?
    private(set) var closeCount = 0

    init(windowNumber: CGWindowID) {
        self.excludedWindowNumber = windowNumber
    }

    func show(relativeTo screenRect: NSRect, screen: NSScreen) {
        shownRect = screenRect
        shownScreen = screen
    }

    func close() {
        closeCount += 1
    }
}
