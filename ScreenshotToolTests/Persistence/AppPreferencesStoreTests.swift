import XCTest
@testable import ScreenshotTool

final class AppPreferencesStoreTests: XCTestCase {
    func testDefaultPreferencesMatchV01Contract() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = AppPreferencesStore(userDefaults: defaults)

        XCTAssertTrue(store.appPreferences.stayResidentAfterClosingWindow)
        XCTAssertTrue(store.appPreferences.showsMenuBarIcon)
        XCTAssertEqual(store.capturePreferences.defaultOutputAction, .copyAndSave)
        XCTAssertEqual(store.annotationPreferences.defaultLineWidth, 4)
        XCTAssertTrue(store.inputMethodPreferences.isEnabled)
    }

    func testUpdateCapturePreferencesPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = AppPreferencesStore(userDefaults: defaults)
        store.updateCapture {
            $0.imageFormat = .jpeg
            $0.defaultOutputAction = .openEditor
        }

        let reloaded = AppPreferencesStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.capturePreferences.imageFormat, .jpeg)
        XCTAssertEqual(reloaded.capturePreferences.defaultOutputAction, .openEditor)
    }
}
