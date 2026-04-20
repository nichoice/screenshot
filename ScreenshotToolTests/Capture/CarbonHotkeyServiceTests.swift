import Carbon
import XCTest
@testable import ScreenshotTool

final class CarbonHotkeyServiceTests: XCTestCase {
    func testCarbonModifiersMapsCommandAndShift() {
        let flags = CarbonHotkeyService.carbonModifiers(for: [.command, .shift])

        XCTAssertEqual(flags, UInt32(cmdKey | shiftKey))
    }
}
