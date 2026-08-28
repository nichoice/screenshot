import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class OverlayViewSelectionBorderMoveTests: XCTestCase {
    func testBatchModeDoesNotTurnAPlainClickIntoFullScreenSelection() throws {
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let window = NSWindow(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view
        let delegate = SelectionDelegateSpy()
        view.overlayDelegate = delegate
        view.requiresManualSelection = true

        view.mouseDown(with: try Self.mouseEvent(.leftMouseDown, at: NSPoint(x: 100, y: 100), in: window))
        view.mouseUp(with: try Self.mouseEvent(.leftMouseUp, at: NSPoint(x: 100, y: 100), in: window))

        XCTAssertEqual(view.state, .idle)
        XCTAssertEqual(view.selectionRect, .zero)
        XCTAssertEqual(delegate.finishSelectionCount, 0)
    }

    func testBatchModeStillCommitsAFreeformDraggedSelection() throws {
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let window = NSWindow(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view
        let delegate = SelectionDelegateSpy()
        view.overlayDelegate = delegate
        view.requiresManualSelection = true

        let start = NSPoint(x: 80, y: 70)
        let end = NSPoint(x: 260, y: 210)
        view.mouseDown(with: try Self.mouseEvent(.leftMouseDown, at: start, in: window))
        view.mouseDragged(with: try Self.mouseEvent(.leftMouseDragged, at: end, in: window))
        view.mouseUp(with: try Self.mouseEvent(.leftMouseUp, at: end, in: window))

        XCTAssertEqual(view.state, .selected)
        XCTAssertEqual(view.selectionRect, NSRect(x: 80, y: 70, width: 180, height: 140))
        XCTAssertEqual(delegate.finishSelectionCount, 1)
    }

    func testDraggingSelectionBorderMovesSelectionWithoutResizing() throws {
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let window = NSWindow(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view

        let original = NSRect(x: 40, y: 40, width: 220, height: 160)
        view.applySelection(original)

        let start = NSPoint(x: 86, y: original.maxY)
        let end = NSPoint(x: 121, y: original.maxY + 25)
        view.mouseDown(with: try Self.mouseEvent(.leftMouseDown, at: start, in: window))
        view.mouseDragged(with: try Self.mouseEvent(.leftMouseDragged, at: end, in: window))
        view.mouseUp(with: try Self.mouseEvent(.leftMouseUp, at: end, in: window))

        XCTAssertEqual(view.selectionRect.origin.x, original.origin.x + 35, accuracy: 0.001)
        XCTAssertEqual(view.selectionRect.origin.y, original.origin.y + 25, accuracy: 0.001)
        XCTAssertEqual(view.selectionRect.width, original.width, accuracy: 0.001)
        XCTAssertEqual(view.selectionRect.height, original.height, accuracy: 0.001)
    }

    private final class SelectionDelegateSpy: OverlayViewDelegate {
        private(set) var finishSelectionCount = 0

        func overlayViewDidFinishSelection(_ rect: NSRect) { finishSelectionCount += 1 }
        func overlayViewSelectionDidChange(_ rect: NSRect) {}
        func overlayViewDidCancel() {}
        func overlayViewDidConfirm() {}
        func overlayViewDidRequestSave() {}
        func overlayViewDidRequestPin() {}
        func overlayViewDidRequestOCR() {}
        func overlayViewDidRequestQuickSave() {}
        func overlayViewDidRequestFileSave() {}
        func overlayViewDidRequestUpload() {}
        func overlayViewDidRequestShare(anchorView: NSView?) {}
        @available(macOS 14.0, *)
        func overlayViewDidRequestRemoveBackground() {}
        func overlayViewDidRequestEnterRecordingMode() {}
        func overlayViewDidRequestStartRecording(rect: NSRect) {}
        func overlayViewDidRequestStopRecording() {}
        func overlayViewDidRequestDetach() {}
        func overlayViewDidRequestScrollCapture(rect: NSRect) {}
        func overlayViewDidRequestStopScrollCapture() {}
        func overlayViewDidRequestToggleAutoScroll() {}
        func overlayViewDidRequestAccessibilityPermission() {}
        func overlayViewDidRequestInputMonitoringPermission() {}
        func overlayViewDidBeginSelection() {}
        func overlayViewRemoteSelectionDidChange(_ rect: NSRect) {}
        func overlayViewDidChangeWindowSnapState() {}
        func overlayViewRemoteSelectionDidFinish(_ rect: NSRect) {}
        func overlayViewDidRequestAddCapture() {}
    }

    private static func mouseEvent(_ type: NSEvent.EventType, at point: NSPoint, in window: NSWindow) throws -> NSEvent {
        try XCTUnwrap(NSEvent.mouseEvent(
            with: type,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: type == .leftMouseUp ? 0 : 1
        ))
    }
}
