import XCTest
@testable import ScreenshotTool

final class SettingsWindowLayoutTests: XCTestCase {
    func testSidebarContainsExpectedTopLevelPages() {
        let items = SettingsSidebarItem.defaultItems

        XCTAssertTrue(items.contains(where: { $0.title == "通用" }))
        XCTAssertTrue(items.contains(where: { $0.title == "外观" }))
        XCTAssertTrue(items.contains(where: { $0.title == "截图" }))
        XCTAssertTrue(items.contains(where: { $0.title == "标注" }))
        XCTAssertTrue(items.contains(where: { $0.title == "输入法规则" }))
        XCTAssertTrue(items.contains(where: { $0.title == "权限与诊断" }))
    }
}
