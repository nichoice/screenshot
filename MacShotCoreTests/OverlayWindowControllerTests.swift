import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class OverlayWindowControllerTests: XCTestCase {
    func testTransparentStartupOverlayStillReceivesMouseEvents() {
        guard let screen = NSScreen.screens.first else {
            XCTFail("Expected at least one screen for overlay tests")
            return
        }
        let controller = OverlayWindowController(screen: screen)

        controller.showOverlay()

        let window = Self.overlayWindow(from: controller)
        XCTAssertNotNil(window)
        XCTAssertFalse(window?.ignoresMouseEvents ?? true)

        controller.dismiss()
    }

    private static func overlayWindow(from controller: OverlayWindowController) -> NSWindow? {
        guard let value = Mirror(reflecting: controller).children.first(where: { $0.label == "overlayWindow" })?.value else {
            return nil
        }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.first?.value as? NSWindow
        }
        return value as? NSWindow
    }
}
