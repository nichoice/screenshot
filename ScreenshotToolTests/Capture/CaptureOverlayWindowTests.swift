import AppKit
import XCTest
@testable import ScreenshotTool

final class CaptureOverlayWindowTests: XCTestCase {
    @MainActor
    func testEscapeKeyInvokesCancelHandler() {
        let window = CaptureOverlayWindow(contentView: NSView(frame: .zero), frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        var didCancel = false
        window.onCancelled = {
            didCancel = true
        }

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            characters: "\u{1b}",
            charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false,
            keyCode: 53
        )!
        window.keyDown(with: event)

        XCTAssertTrue(didCancel)
    }

    @MainActor
    func testSendEventEscapeKeyInvokesCancelHandler() {
        let window = CaptureOverlayWindow(contentView: NSView(frame: .zero), frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        var didCancel = false
        window.onCancelled = {
            didCancel = true
        }

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            characters: "\u{1b}",
            charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false,
            keyCode: 53
        )!
        window.sendEvent(event)

        XCTAssertTrue(didCancel)
    }
}
