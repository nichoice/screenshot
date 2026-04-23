import XCTest
@testable import ScreenshotTool

final class CaptureSelectionTests: XCTestCase {
    func testNormalizedRectUsesMinimumOriginAndAbsoluteSize() {
        let selection = CaptureSelection(start: CGPoint(x: 300, y: 400), end: CGPoint(x: 120, y: 220))

        XCTAssertEqual(selection.normalizedRect, CGRect(x: 120, y: 220, width: 180, height: 180))
    }

    func testLocalPointToGlobalAddsScreenOrigin() {
        let point = CaptureCoordinateConverter.localPointToGlobal(
            CGPoint(x: 40, y: 60),
            screenFrame: CGRect(x: 1000, y: 200, width: 400, height: 300)
        )

        XCTAssertEqual(point, CGPoint(x: 1040, y: 260))
    }

    func testAppKitRectToCGWindowRectFlipsYWithinScreenFrame() {
        let rect = CaptureCoordinateConverter.appKitRectToCGWindowRect(
            CGRect(x: 20, y: 100, width: 80, height: 50),
            screenFrame: CGRect(x: 0, y: 0, width: 400, height: 300)
        )

        XCTAssertEqual(rect, CGRect(x: 20, y: 150, width: 80, height: 50))
    }

    func testAppKitPointToCGWindowPointFlipsYWithinScreenFrame() {
        let point = CaptureCoordinateConverter.appKitPointToCGWindowPoint(
            CGPoint(x: 20, y: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 400, height: 300)
        )

        XCTAssertEqual(point, CGPoint(x: 20, y: 200))
    }

    func testCGWindowRectToAppKitRectFlipsBackWithinScreenFrame() {
        let rect = CaptureCoordinateConverter.cgWindowRectToAppKitRect(
            CGRect(x: 20, y: 150, width: 80, height: 50),
            screenFrame: CGRect(x: 0, y: 0, width: 400, height: 300)
        )

        XCTAssertEqual(rect, CGRect(x: 20, y: 100, width: 80, height: 50))
    }

    func testGlobalRectToLocalSubtractsScreenOrigin() {
        let rect = CaptureCoordinateConverter.globalRectToLocal(
            CGRect(x: 1020, y: 240, width: 220, height: 140),
            screenFrame: CGRect(x: 1000, y: 200, width: 400, height: 300)
        )

        XCTAssertEqual(rect, CGRect(x: 20, y: 40, width: 220, height: 140))
    }

    func testDragSelectionStagesRectWithoutConfirmingImmediately() {
        var state = CaptureOverlayInteractionState()

        state.handleMouseDown(at: CGPoint(x: 40, y: 50))
        let dragActions = state.handleMouseDragged(to: CGPoint(x: 220, y: 180))
        let endActions = state.handleMouseUp(at: CGPoint(x: 220, y: 180))

        XCTAssertEqual(dragActions, [.selectionUpdated(CGRect(x: 40, y: 50, width: 180, height: 130))])
        XCTAssertEqual(endActions, [
            .selectionUpdated(CGRect(x: 40, y: 50, width: 180, height: 130)),
            .selectionConfirmed
        ])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 40, y: 50, width: 180, height: 130))
    }

    func testClickInsideStagedSelectionConfirmsSelection() {
        var state = CaptureOverlayInteractionState()
        state.stagedSelectionRect = CGRect(x: 40, y: 50, width: 180, height: 130)

        state.handleMouseDown(at: CGPoint(x: 120, y: 110))
        let actions = state.handleMouseUp(at: CGPoint(x: 120, y: 110))

        XCTAssertEqual(actions, [.selectionConfirmed])
    }

    func testClickHoveredWindowStagesAndConfirmsWindowSelection() {
        var state = CaptureOverlayInteractionState()
        state.hoveredWindowRect = CGRect(x: 80, y: 90, width: 260, height: 180)

        state.handleMouseDown(at: CGPoint(x: 160, y: 140))
        let actions = state.handleMouseUp(at: CGPoint(x: 160, y: 140))

        XCTAssertEqual(actions, [
            .selectionUpdated(CGRect(x: 80, y: 90, width: 260, height: 180)),
            .selectionConfirmed
        ])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 80, y: 90, width: 260, height: 180))
    }

    func testDragInsideStagedSelectionMovesSelectionWithoutConfirming() {
        var state = CaptureOverlayInteractionState()
        state.stagedSelectionRect = CGRect(x: 40, y: 50, width: 180, height: 130)

        state.handleMouseDown(at: CGPoint(x: 120, y: 110))
        let dragActions = state.handleMouseDragged(to: CGPoint(x: 170, y: 150))
        let endActions = state.handleMouseUp(at: CGPoint(x: 170, y: 150))

        XCTAssertEqual(dragActions, [.selectionUpdated(CGRect(x: 90, y: 90, width: 180, height: 130))])
        XCTAssertEqual(endActions, [.selectionUpdated(CGRect(x: 90, y: 90, width: 180, height: 130))])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 90, y: 90, width: 180, height: 130))
    }

    func testClickInsideMovedStagedSelectionStillConfirmsSelection() {
        var state = CaptureOverlayInteractionState()
        state.stagedSelectionRect = CGRect(x: 90, y: 90, width: 180, height: 130)

        state.handleMouseDown(at: CGPoint(x: 140, y: 140))
        let actions = state.handleMouseUp(at: CGPoint(x: 140, y: 140))

        XCTAssertEqual(actions, [.selectionConfirmed])
    }

    func testDraggingStagedSelectionClampsWithinAvailableRect() {
        var state = CaptureOverlayInteractionState()
        state.availableRect = CGRect(x: 0, y: 0, width: 300, height: 220)
        state.stagedSelectionRect = CGRect(x: 120, y: 90, width: 180, height: 130)

        state.handleMouseDown(at: CGPoint(x: 220, y: 140))
        let dragActions = state.handleMouseDragged(to: CGPoint(x: 260, y: 190))
        let endActions = state.handleMouseUp(at: CGPoint(x: 260, y: 190))

        XCTAssertEqual(dragActions, [.selectionUpdated(CGRect(x: 120, y: 90, width: 180, height: 130))])
        XCTAssertEqual(endActions, [.selectionUpdated(CGRect(x: 120, y: 90, width: 180, height: 130))])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 120, y: 90, width: 180, height: 130))
    }

    func testDraggingTrailingHandleResizesStagedSelection() {
        var state = CaptureOverlayInteractionState()
        state.availableRect = CGRect(x: 0, y: 0, width: 400, height: 260)
        state.stagedSelectionRect = CGRect(x: 40, y: 50, width: 180, height: 130)
        let handlePoint = CGPoint(x: 220, y: 115)

        state.handleMouseDown(at: handlePoint)
        let dragActions = state.handleMouseDragged(to: CGPoint(x: 260, y: 115))
        let endActions = state.handleMouseUp(at: CGPoint(x: 260, y: 115))

        XCTAssertEqual(dragActions, [.selectionUpdated(CGRect(x: 40, y: 50, width: 220, height: 130))])
        XCTAssertEqual(endActions, [.selectionUpdated(CGRect(x: 40, y: 50, width: 220, height: 130))])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 40, y: 50, width: 220, height: 130))
    }

    func testDraggingLeadingHandleKeepsMinimumSelectionWidth() {
        var state = CaptureOverlayInteractionState()
        state.availableRect = CGRect(x: 0, y: 0, width: 400, height: 260)
        state.stagedSelectionRect = CGRect(x: 40, y: 50, width: 180, height: 130)
        let handlePoint = CGPoint(x: 40, y: 115)

        state.handleMouseDown(at: handlePoint)
        let dragActions = state.handleMouseDragged(to: CGPoint(x: 250, y: 115))
        let endActions = state.handleMouseUp(at: CGPoint(x: 250, y: 115))

        XCTAssertEqual(dragActions, [.selectionUpdated(CGRect(x: 172, y: 50, width: 48, height: 130))])
        XCTAssertEqual(endActions, [.selectionUpdated(CGRect(x: 172, y: 50, width: 48, height: 130))])
        XCTAssertEqual(state.stagedSelectionRect, CGRect(x: 172, y: 50, width: 48, height: 130))
    }
}
