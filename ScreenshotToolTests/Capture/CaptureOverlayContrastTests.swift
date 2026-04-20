import XCTest
@testable import ScreenshotTool

final class CaptureOverlayContrastTests: XCTestCase {
    func testContrastHelperChoosesLightBorderOnDarkBackground() {
        XCTAssertEqual(CaptureOverlayContrast.borderStyle(forBackgroundLuminance: 0.1), .light)
    }
}
