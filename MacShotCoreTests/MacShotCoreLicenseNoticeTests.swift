import XCTest
@testable import MacShotCore

final class MacShotCoreLicenseNoticeTests: XCTestCase {
    func testNoticeNamesMacshotAndGPLv3() {
        XCTAssertTrue(MacShotCoreLicenseNotice.sourceProject.contains("macshot"))
        XCTAssertEqual(MacShotCoreLicenseNotice.license, "GPLv3")
        XCTAssertTrue(MacShotCoreLicenseNotice.sourcePath.contains("/macshot"))
    }
}
