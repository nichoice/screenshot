import XCTest
@testable import ScreenshotTool

final class AppPreferencesStoreTests: XCTestCase {
    func testDefaultPreferencesMatchV01Contract() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = AppPreferencesStore(userDefaults: defaults)

        XCTAssertTrue(store.appPreferences.stayResidentAfterClosingWindow)
        XCTAssertTrue(store.appPreferences.showsMenuBarIcon)
        XCTAssertEqual(store.capturePreferences.hotkey, GlobalHotkey(keyCode: 21, modifiers: [.command, .shift]))
        XCTAssertEqual(store.capturePreferences.defaultOutputAction, .copyAndSave)
        XCTAssertEqual(store.capturePreferences.defaultSaveDirectoryPath, FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path)
        XCTAssertEqual(store.annotationPreferences.defaultLineWidth, 4)
        XCTAssertTrue(store.inputMethodPreferences.isEnabled)
    }

    func testGlobalHotkeyDisplayNameUsesReadableModifierOrder() {
        let hotkey = GlobalHotkey(keyCode: 12, modifiers: [.shift, .command])

        XCTAssertEqual(hotkey.displayName, "Command + Shift + Q")
    }

    func testUpdateCapturePreferencesPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = AppPreferencesStore(userDefaults: defaults)
        store.updateCapture {
            $0.imageFormat = .jpeg
            $0.defaultOutputAction = .openEditor
            $0.defaultSaveDirectoryPath = "/tmp/ScreenshotToolCustom"
            $0.playCaptureSound = true
        }

        let reloaded = AppPreferencesStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.capturePreferences.imageFormat, .jpeg)
        XCTAssertEqual(reloaded.capturePreferences.defaultOutputAction, .openEditor)
        XCTAssertEqual(reloaded.capturePreferences.defaultSaveDirectoryPath, "/tmp/ScreenshotToolCustom")
        XCTAssertTrue(reloaded.capturePreferences.playCaptureSound)
    }

    func testLegacyDefaultCaptureHotkeyMigratesToCommandShift4() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let legacy = CapturePreferences(
            hotkey: GlobalHotkey(keyCode: 23, modifiers: [.command, .shift]),
            defaultSaveDirectoryPath: nil,
            defaultOutputAction: .copyAndSave,
            imageFormat: .png,
            includeCursor: false,
            playCaptureSound: false
        )
        let data = try JSONEncoder().encode(legacy)
        defaults.set(data, forKey: "capture")

        let store = AppPreferencesStore(userDefaults: defaults)

        XCTAssertEqual(store.capturePreferences.hotkey, .defaultCapture)
        XCTAssertEqual(store.capturePreferences.defaultSaveDirectoryPath, FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path)
    }

    func testLegacyBundlePreferencesMigrateWithoutOverwritingNewValues() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let legacyApp = AppPreferences(
            stayResidentAfterClosingWindow: true,
            showsMenuBarIcon: false,
            launchAtLogin: true,
            themePreference: .dark
        )
        let legacyCapture = CapturePreferences(
            hotkey: .defaultCapture,
            defaultSaveDirectoryPath: "/tmp/legacy-snapshots",
            defaultOutputAction: .saveOnly,
            imageFormat: .jpeg,
            includeCursor: true,
            playCaptureSound: true
        )
        let currentApp = AppPreferences(
            stayResidentAfterClosingWindow: true,
            showsMenuBarIcon: true,
            launchAtLogin: false,
            themePreference: .light
        )
        defaults.set(try JSONEncoder().encode(currentApp), forKey: "app")

        let store = AppPreferencesStore(
            userDefaults: defaults,
            legacyPersistentDomain: [
                "app": try JSONEncoder().encode(legacyApp),
                "capture": try JSONEncoder().encode(legacyCapture),
            ]
        )

        XCTAssertEqual(store.appPreferences.themePreference, .light)
        XCTAssertEqual(store.capturePreferences.defaultOutputAction, .saveOnly)
        XCTAssertEqual(store.capturePreferences.defaultSaveDirectoryPath, "/tmp/legacy-snapshots")
    }
}
