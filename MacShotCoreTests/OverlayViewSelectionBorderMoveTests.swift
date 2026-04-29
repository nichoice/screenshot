import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class OverlayViewSelectionBorderMoveTests: XCTestCase {
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
