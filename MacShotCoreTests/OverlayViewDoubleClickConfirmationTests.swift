import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class OverlayViewDoubleClickConfirmationTests: XCTestCase {
    func testDoubleClickInsideSelectedAreaRequestsQuickSave() throws {
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let window = NSWindow(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view

        let delegate = OverlayViewDelegateSpy()
        view.overlayDelegate = delegate
        view.currentTool = .arrow
        view.applySelection(NSRect(x: 40, y: 40, width: 220, height: 160))

        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 2,
            pressure: 1
        ))

        view.mouseDown(with: event)

        XCTAssertEqual(delegate.quickSaveRequestCount, 1)
    }

    func testDoubleClickCommitsTextAndClearsTransientEditingChromeBeforeQuickSave() throws {
        let view = OverlayView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let window = NSWindow(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view

        let delegate = OverlayViewDelegateSpy()
        view.overlayDelegate = delegate
        view.currentTool = .text
        view.applySelection(NSRect(x: 40, y: 40, width: 220, height: 160))
        view.beginTextEditingForTesting(at: NSPoint(x: 100, y: 100), text: "hello")

        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 110, y: 110),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 2,
            clickCount: 2,
            pressure: 1
        ))

        view.mouseDown(with: event)

        XCTAssertEqual(delegate.quickSaveRequestCount, 1)
        XCTAssertNil(view.textEditView)
        XCTAssertFalse(view.showToolbars)
        XCTAssertEqual(view.selectedAnnotationCountForTesting, 0)
        XCTAssertEqual(view.annotations.count, 1)
        XCTAssertEqual(view.annotations.first?.tool, .text)
        XCTAssertEqual(view.annotations.first?.text, "hello")
    }
}

@MainActor
private final class OverlayViewDelegateSpy: OverlayViewDelegate {
    private(set) var quickSaveRequestCount = 0

    func overlayViewDidFinishSelection(_ rect: NSRect) {}
    func overlayViewSelectionDidChange(_ rect: NSRect) {}
    func overlayViewDidCancel() {}
    func overlayViewDidConfirm() {}
    func overlayViewDidRequestSave() {}
    func overlayViewDidRequestPin() {}
    func overlayViewDidRequestOCR() {}
    func overlayViewDidRequestQuickSave() { quickSaveRequestCount += 1 }
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
