import AppKit
import XCTest
@testable import ScreenshotTool

@MainActor
final class MacShotOutputRoutingTests: XCTestCase {
    func testMacShotCompletionRefreshesRecentCaptures() {
        let environment = AppEnvironment.bootstrapForTests()
        environment.preferencesStore.updateCapture { $0.defaultOutputAction = .copyOnly }
        let image = Self.makeImage()

        environment.handleMacShotCaptureResultForTesting(
            image: image,
            capturedAt: Date(timeIntervalSince1970: 500)
        )

        environment.mainWindowViewModel.refresh()
        XCTAssertEqual(environment.mainWindowViewModel.recentCaptures.count, 1)
    }

    private static func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 8))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 8, height: 8).fill()
        image.unlockFocus()
        return image
    }
}
