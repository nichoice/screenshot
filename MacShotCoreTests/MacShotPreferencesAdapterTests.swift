import XCTest
@testable import MacShotCore

final class MacShotPreferencesAdapterTests: XCTestCase {
    func testApplyWritesMacshotDefaults() {
        let defaults = UserDefaults(suiteName: "MacShotPreferencesAdapterTests")!
        defaults.removePersistentDomain(forName: "MacShotPreferencesAdapterTests")
        let adapter = MacShotPreferencesAdapter(userDefaults: defaults)

        adapter.apply(
            MacShotPreferences(
                defaultColorHex: "#00AAFF",
                defaultLineWidth: 7,
                defaultFontSize: 22,
                rememberLastTool: false,
                includeCursor: true,
                defaultSaveDirectoryPath: "/tmp/ScreenshotTool"
            )
        )

        XCTAssertEqual(defaults.string(forKey: "ScreenshotTool.defaultColorHex"), "#00AAFF")
        XCTAssertEqual(defaults.double(forKey: "currentStrokeWidth"), 7)
        XCTAssertEqual(defaults.double(forKey: "textFontSize"), 22)
        XCTAssertFalse(defaults.bool(forKey: "rememberLastTool"))
        XCTAssertTrue(defaults.bool(forKey: "captureCursor"))
        XCTAssertEqual(defaults.string(forKey: "saveDirectory"), "/tmp/ScreenshotTool")
    }
}
