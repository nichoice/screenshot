# macOS Screenshot Tool v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS screenshot utility with global hotkey capture, QQ/WeChat-style region selection and annotation, save/copy/pin actions, recent history, and a settings-hosted input method automation feature with global default plus per-app overrides.

**Architecture:** Use a hybrid native stack: `SwiftUI` for the main window and settings surfaces, `AppKit` for overlays, pinned windows, and toolbar windows, and small protocol-driven services for system integrations like screen capture, hotkeys, permissions, login items, and input source switching. Keep screenshot capture, annotation, persistence, and input method automation as separate modules so the app can ship a stable screenshot v0.1 even if system-specific input source behavior needs iteration.

**Tech Stack:** Swift 5.10+, SwiftUI, AppKit, Combine, CoreGraphics, CoreImage, Carbon/HIToolbox, ServiceManagement, XCTest, XcodeGen

---

## Preflight

Before Task 1, create an isolated worktree for implementation and switch into it:

```bash
git worktree add ../screenshot-v0.1 -b feat/screenshot-tool-v0.1
cd ../screenshot-v0.1
```

Install the one project-generation dependency the plan assumes:

```bash
brew install xcodegen
```

Verify local toolchain state:

```bash
xcode-select -p
xcodebuild -version
xcodegen --version
```

Expected:

- `xcode-select -p` prints the active Xcode developer path
- `xcodebuild -version` prints Xcode and build versions
- `xcodegen --version` prints a semantic version string

## Planned File Structure

### Root Configuration

- Create: `project.yml` - Versioned XcodeGen definition for the app and test targets
- Create: `Makefile` - Convenience commands for project generation and targeted test runs

### App Shell

- Create: `ScreenshotTool/App/ScreenshotToolApp.swift` - SwiftUI app entry point
- Create: `ScreenshotTool/App/AppDelegate.swift` - macOS app lifecycle, resident behavior, and startup wiring
- Create: `ScreenshotTool/App/AppEnvironment.swift` - Composition root for stores, services, coordinators, and view models
- Create: `ScreenshotTool/App/WindowRouter.swift` - Opens settings, overlay windows, floating toolbar, editor, and pin windows
- Create: `ScreenshotTool/App/MenuBarController.swift` - Optional menu bar item and popover actions
- Create: `ScreenshotTool/App/CaptureHotkeyHandler.swift` - Registers the configured global hotkey and forwards to the capture coordinator

### Settings, Main Window, and System Status

- Create: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
- Create: `ScreenshotTool/Features/Main/MainWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/SettingsWindowViewModel.swift`
- Create: `ScreenshotTool/Features/Settings/SettingsWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/GeneralSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/ScreenshotSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/AnnotationSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/InputMethodSettingsView.swift`

### Persistence

- Create: `ScreenshotTool/Persistence/AppPreferences.swift`
- Create: `ScreenshotTool/Persistence/AppPreferencesStore.swift`
- Create: `ScreenshotTool/Persistence/InputMethodRule.swift`
- Create: `ScreenshotTool/Persistence/InputMethodRulesStore.swift`
- Create: `ScreenshotTool/Persistence/CaptureHistoryItem.swift`
- Create: `ScreenshotTool/Persistence/CaptureHistoryStore.swift`

### Input Method Automation

- Create: `ScreenshotTool/InputMethod/InputSourceDescriptor.swift`
- Create: `ScreenshotTool/InputMethod/InputSourceService.swift`
- Create: `ScreenshotTool/InputMethod/TISInputSourceService.swift`
- Create: `ScreenshotTool/InputMethod/FrontmostApplicationObserver.swift`
- Create: `ScreenshotTool/InputMethod/WorkspaceFrontmostApplicationObserver.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodRuleMatcher.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodAutomationStatus.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodManager.swift`

### Screenshot Capture

- Create: `ScreenshotTool/Capture/CaptureSelection.swift`
- Create: `ScreenshotTool/Capture/CaptureResult.swift`
- Create: `ScreenshotTool/Capture/ScreenCaptureService.swift`
- Create: `ScreenshotTool/Capture/WindowListScreenCaptureService.swift`
- Create: `ScreenshotTool/Capture/CaptureCoordinator.swift`
- Create: `ScreenshotTool/Capture/Hotkeys/HotkeyService.swift`
- Create: `ScreenshotTool/Capture/Hotkeys/CarbonHotkeyService.swift`
- Create: `ScreenshotTool/Capture/Overlay/CaptureOverlayWindow.swift`
- Create: `ScreenshotTool/Capture/Overlay/CaptureOverlayView.swift`
- Create: `ScreenshotTool/Capture/CaptureOutputService.swift`
- Create: `ScreenshotTool/Capture/ClipboardService.swift`
- Create: `ScreenshotTool/Capture/PasteboardClipboardService.swift`

### Annotation and Output Windows

- Create: `ScreenshotTool/Annotation/AnnotationTool.swift`
- Create: `ScreenshotTool/Annotation/AnnotationItem.swift`
- Create: `ScreenshotTool/Annotation/AnnotationDocument.swift`
- Create: `ScreenshotTool/Annotation/AnnotationRenderer.swift`
- Create: `ScreenshotTool/Annotation/AnnotationCanvasView.swift`
- Create: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarPlacement.swift`
- Create: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarController.swift`
- Create: `ScreenshotTool/Annotation/Editor/EditorWindowController.swift`
- Create: `ScreenshotTool/Annotation/Pin/PinWindowController.swift`

### Permissions and Login Items

- Create: `ScreenshotTool/Support/Permissions/PermissionsService.swift`
- Create: `ScreenshotTool/Support/Permissions/DefaultPermissionsService.swift`
- Create: `ScreenshotTool/Support/LoginItemService.swift`
- Create: `ScreenshotTool/Support/SystemLoginItemService.swift`

### Tests

- Create: `ScreenshotToolTests/Smoke/ScreenshotToolSmokeTests.swift`
- Create: `ScreenshotToolTests/Persistence/AppPreferencesStoreTests.swift`
- Create: `ScreenshotToolTests/Persistence/InputMethodRulesStoreTests.swift`
- Create: `ScreenshotToolTests/Persistence/CaptureHistoryStoreTests.swift`
- Create: `ScreenshotToolTests/InputMethod/InputMethodRuleMatcherTests.swift`
- Create: `ScreenshotToolTests/InputMethod/InputMethodManagerTests.swift`
- Create: `ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift`
- Create: `ScreenshotToolTests/Capture/CaptureSelectionTests.swift`
- Create: `ScreenshotToolTests/Capture/CaptureCoordinatorTests.swift`
- Create: `ScreenshotToolTests/Capture/CaptureHotkeyHandlerTests.swift`
- Create: `ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift`
- Create: `ScreenshotToolTests/Annotation/AnnotationDocumentTests.swift`
- Create: `ScreenshotToolTests/Annotation/FloatingToolbarPlacementTests.swift`
- Create: `ScreenshotToolTests/Features/MainWindowViewModelTests.swift`

## Task 1: Bootstrap the Native macOS Project

**Files:**
- Create: `project.yml`
- Create: `Makefile`
- Create: `ScreenshotTool/App/ScreenshotToolApp.swift`
- Create: `ScreenshotTool/App/AppDelegate.swift`
- Create: `ScreenshotTool/App/AppEnvironment.swift`
- Create: `ScreenshotTool/Features/Main/MainWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/SettingsWindowView.swift`
- Test: `ScreenshotToolTests/Smoke/ScreenshotToolSmokeTests.swift`

- [ ] **Step 1: Add the project definition and local commands**

```yaml
name: ScreenshotTool
options:
  bundleIdPrefix: com.nic
settings:
  base:
    SWIFT_VERSION: 5.10
targets:
  ScreenshotTool:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - ScreenshotTool
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.nic.ScreenshotTool
        PRODUCT_NAME: ScreenshotTool
        GENERATE_INFOPLIST_FILE: YES
  ScreenshotToolTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - ScreenshotToolTests
    dependencies:
      - target: ScreenshotTool
```

```make
PROJECT = ScreenshotTool.xcodeproj
SCHEME = ScreenshotTool
DESTINATION = platform=macOS

generate:
	xcodegen generate

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)'

test-only:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -only-testing:$(TEST)
```

- [ ] **Step 2: Generate the Xcode project**

Run: `make generate`

Expected: `Generated project at /Users/nic/Documents/workspace/screenshot/ScreenshotTool.xcodeproj`

- [ ] **Step 3: Write the failing smoke test**

```swift
import XCTest
@testable import ScreenshotTool

final class ScreenshotToolSmokeTests: XCTestCase {
    @MainActor
    func testAppEnvironmentExposesExpectedTitle() {
        let environment = AppEnvironment.bootstrapForTests()
        XCTAssertEqual(environment.windowTitle, "Screenshot Tool")
    }
}
```

- [ ] **Step 4: Run the smoke test to verify it fails**

Run: `make test-only TEST=ScreenshotToolTests/ScreenshotToolSmokeTests/testAppEnvironmentExposesExpectedTitle`

Expected: FAIL with `Cannot find 'AppEnvironment' in scope`

- [ ] **Step 5: Add the minimal app entry, environment, and placeholder views**

```swift
import SwiftUI

@main
struct ScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup(environment.windowTitle) {
            MainWindowView(title: environment.windowTitle)
        }
        Settings {
            SettingsWindowView()
        }
    }
}
```

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {}
}
```

```swift
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String

    init(windowTitle: String = "Screenshot Tool") {
        self.windowTitle = windowTitle
    }

    static func bootstrap() -> AppEnvironment {
        AppEnvironment()
    }

    static func bootstrapForTests() -> AppEnvironment {
        AppEnvironment()
    }
}
```

```swift
import SwiftUI

struct MainWindowView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle)
            Text("Project bootstrap complete")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
    }
}
```

```swift
import SwiftUI

struct SettingsWindowView: View {
    var body: some View {
        Text("Settings will be implemented in later tasks")
            .frame(width: 480, height: 320)
            .padding(24)
    }
}
```

- [ ] **Step 6: Run the smoke test to verify it passes**

Run: `make test-only TEST=ScreenshotToolTests/ScreenshotToolSmokeTests/testAppEnvironmentExposesExpectedTitle`

Expected: PASS and `** TEST SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add project.yml Makefile ScreenshotTool ScreenshotToolTests
git commit -m "chore: bootstrap macOS app project"
```

## Task 2: Add Preferences Models and Store

**Files:**
- Create: `ScreenshotTool/Persistence/AppPreferences.swift`
- Create: `ScreenshotTool/Persistence/AppPreferencesStore.swift`
- Test: `ScreenshotToolTests/Persistence/AppPreferencesStoreTests.swift`

- [ ] **Step 1: Write failing persistence tests**

```swift
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
```

- [ ] **Step 2: Run the persistence tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/AppPreferencesStoreTests`

Expected: FAIL with `Cannot find 'AppPreferencesStore' in scope`

- [ ] **Step 3: Implement the preference types and store**

```swift
import Foundation

enum HotkeyModifier: String, Codable, CaseIterable {
    case command
    case option
    case control
    case shift
}

struct GlobalHotkey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: [HotkeyModifier]

    static let defaultCapture = GlobalHotkey(keyCode: 23, modifiers: [.command, .shift])
}

enum CaptureOutputAction: String, Codable, CaseIterable {
    case copyOnly
    case saveOnly
    case copyAndSave
    case openEditor
}

enum CaptureImageFormat: String, Codable, CaseIterable {
    case png
    case jpeg
}

struct AppPreferences: Codable, Equatable {
    var stayResidentAfterClosingWindow: Bool = true
    var showsMenuBarIcon: Bool = true
    var launchAtLogin: Bool = false
}

struct CapturePreferences: Codable, Equatable {
    var hotkey: GlobalHotkey = .defaultCapture
    var defaultSaveDirectoryPath: String? = nil
    var defaultOutputAction: CaptureOutputAction = .copyAndSave
    var imageFormat: CaptureImageFormat = .png
    var includeCursor: Bool = false
    var playCaptureSound: Bool = false
}

struct AnnotationPreferences: Codable, Equatable {
    var defaultColorHex: String = "#FF3B30"
    var defaultLineWidth: Double = 4
    var defaultFontSize: Double = 16
    var rememberLastTool: Bool = true
    var pinWindowsFloatOnTop: Bool = true
    var historyLimit: Int = 20
}

struct InputMethodPreferences: Codable, Equatable {
    var isEnabled: Bool = true
    var globalDefaultInputSourceID: String? = nil
}
```

```swift
import Foundation

@MainActor
final class AppPreferencesStore: ObservableObject {
    private enum Key: String {
        case app
        case capture
        case annotation
        case inputMethod
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var appPreferences: AppPreferences
    @Published private(set) var capturePreferences: CapturePreferences
    @Published private(set) var annotationPreferences: AnnotationPreferences
    @Published private(set) var inputMethodPreferences: InputMethodPreferences

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.appPreferences = Self.load(AppPreferences.self, key: .app, from: userDefaults) ?? AppPreferences()
        self.capturePreferences = Self.load(CapturePreferences.self, key: .capture, from: userDefaults) ?? CapturePreferences()
        self.annotationPreferences = Self.load(AnnotationPreferences.self, key: .annotation, from: userDefaults) ?? AnnotationPreferences()
        self.inputMethodPreferences = Self.load(InputMethodPreferences.self, key: .inputMethod, from: userDefaults) ?? InputMethodPreferences()
    }

    func updateApp(_ mutate: (inout AppPreferences) -> Void) {
        mutate(&appPreferences)
        save(appPreferences, key: .app)
    }

    func updateCapture(_ mutate: (inout CapturePreferences) -> Void) {
        mutate(&capturePreferences)
        save(capturePreferences, key: .capture)
    }

    func updateAnnotation(_ mutate: (inout AnnotationPreferences) -> Void) {
        mutate(&annotationPreferences)
        save(annotationPreferences, key: .annotation)
    }

    func updateInputMethod(_ mutate: (inout InputMethodPreferences) -> Void) {
        mutate(&inputMethodPreferences)
        save(inputMethodPreferences, key: .inputMethod)
    }

    private func save<T: Encodable>(_ value: T, key: Key) {
        let data = try! encoder.encode(value)
        userDefaults.set(data, forKey: key.rawValue)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: Key, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
```

- [ ] **Step 4: Run the persistence tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/AppPreferencesStoreTests`

Expected: PASS and `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Persistence/AppPreferences.swift ScreenshotTool/Persistence/AppPreferencesStore.swift ScreenshotToolTests/Persistence/AppPreferencesStoreTests.swift
git commit -m "feat: add preference models and store"
```

## Task 3: Add Input Method Rules, Store, and Matcher

**Files:**
- Create: `ScreenshotTool/Persistence/InputMethodRule.swift`
- Create: `ScreenshotTool/Persistence/InputMethodRulesStore.swift`
- Create: `ScreenshotTool/InputMethod/InputSourceDescriptor.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodRuleMatcher.swift`
- Test: `ScreenshotToolTests/Persistence/InputMethodRulesStoreTests.swift`
- Test: `ScreenshotToolTests/InputMethod/InputMethodRuleMatcherTests.swift`

- [ ] **Step 1: Write failing rule-store and matcher tests**

```swift
import XCTest
@testable import ScreenshotTool

final class InputMethodRulesStoreTests: XCTestCase {
    func testUpsertPersistsRuleToDisk() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: fileURL)

        let store = InputMethodRulesStore(fileURL: fileURL)
        let rule = AppInputMethodRule(
            id: UUID(),
            bundleIdentifier: "com.apple.Terminal",
            appName: "Terminal",
            inputSourceID: "com.apple.keylayout.US",
            isEnabled: true
        )

        try store.upsert(rule)

        let reloaded = InputMethodRulesStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.rules, [rule])
    }
}
```

```swift
import XCTest
@testable import ScreenshotTool

final class InputMethodRuleMatcherTests: XCTestCase {
    func testResolvePrefersEnabledAppRuleOverGlobalDefault() {
        let matcher = InputMethodRuleMatcher()
        let preferences = InputMethodPreferences(isEnabled: true, globalDefaultInputSourceID: "com.apple.keylayout.ABC")
        let rules = [
            AppInputMethodRule(
                id: UUID(),
                bundleIdentifier: "com.apple.Terminal",
                appName: "Terminal",
                inputSourceID: "com.apple.keylayout.US",
                isEnabled: true
            )
        ]

        let resolution = matcher.resolve(
            bundleIdentifier: "com.apple.Terminal",
            preferences: preferences,
            rules: rules
        )

        XCTAssertEqual(resolution.targetInputSourceID, "com.apple.keylayout.US")
        XCTAssertEqual(resolution.source, .appRule)
    }

    func testResolveFallsBackToGlobalDefaultWhenNoRuleMatches() {
        let matcher = InputMethodRuleMatcher()
        let preferences = InputMethodPreferences(isEnabled: true, globalDefaultInputSourceID: "com.apple.keylayout.ABC")

        let resolution = matcher.resolve(
            bundleIdentifier: "com.apple.TextEdit",
            preferences: preferences,
            rules: []
        )

        XCTAssertEqual(resolution.targetInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertEqual(resolution.source, .globalDefault)
    }
}
```

- [ ] **Step 2: Run the rule tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/InputMethodRulesStoreTests`

Expected: FAIL with `Cannot find 'InputMethodRulesStore' in scope`

Run: `make test-only TEST=ScreenshotToolTests/InputMethodRuleMatcherTests`

Expected: FAIL with `Cannot find 'InputMethodRuleMatcher' in scope`

- [ ] **Step 3: Implement the rule model, JSON store, and matcher**

```swift
import Foundation

struct AppInputMethodRule: Codable, Equatable, Identifiable {
    let id: UUID
    var bundleIdentifier: String
    var appName: String
    var inputSourceID: String
    var isEnabled: Bool
}
```

```swift
import Foundation

@MainActor
final class InputMethodRulesStore: ObservableObject {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var rules: [AppInputMethodRule]

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([AppInputMethodRule].self, from: data) {
            self.rules = decoded
        } else {
            self.rules = []
        }
    }

    func upsert(_ rule: AppInputMethodRule) throws {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        try save()
    }

    func remove(id: UUID) throws {
        rules.removeAll { $0.id == id }
        try save()
    }

    private func save() throws {
        let data = try encoder.encode(rules)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
```

```swift
import Foundation

struct InputSourceDescriptor: Equatable, Identifiable {
    let id: String
    let localizedName: String
}
```

```swift
import Foundation

enum InputMethodResolutionSource: Equatable {
    case disabled
    case appRule
    case globalDefault
    case none
}

struct InputMethodResolution: Equatable {
    let bundleIdentifier: String?
    let targetInputSourceID: String?
    let source: InputMethodResolutionSource
}

struct InputMethodRuleMatcher {
    func resolve(
        bundleIdentifier: String?,
        preferences: InputMethodPreferences,
        rules: [AppInputMethodRule]
    ) -> InputMethodResolution {
        guard preferences.isEnabled else {
            return InputMethodResolution(bundleIdentifier: bundleIdentifier, targetInputSourceID: nil, source: .disabled)
        }

        if let bundleIdentifier,
           let rule = rules.first(where: { $0.bundleIdentifier == bundleIdentifier && $0.isEnabled }) {
            return InputMethodResolution(bundleIdentifier: bundleIdentifier, targetInputSourceID: rule.inputSourceID, source: .appRule)
        }

        if let globalID = preferences.globalDefaultInputSourceID {
            return InputMethodResolution(bundleIdentifier: bundleIdentifier, targetInputSourceID: globalID, source: .globalDefault)
        }

        return InputMethodResolution(bundleIdentifier: bundleIdentifier, targetInputSourceID: nil, source: .none)
    }
}
```

- [ ] **Step 4: Run the rule tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/InputMethodRulesStoreTests`

Expected: PASS

Run: `make test-only TEST=ScreenshotToolTests/InputMethodRuleMatcherTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Persistence/InputMethodRule.swift ScreenshotTool/Persistence/InputMethodRulesStore.swift ScreenshotTool/InputMethod/InputSourceDescriptor.swift ScreenshotTool/InputMethod/InputMethodRuleMatcher.swift ScreenshotToolTests/Persistence/InputMethodRulesStoreTests.swift ScreenshotToolTests/InputMethod/InputMethodRuleMatcherTests.swift
git commit -m "feat: add input method rule persistence"
```

## Task 4: Add Input Method Manager and System Adapters

**Files:**
- Create: `ScreenshotTool/InputMethod/InputSourceService.swift`
- Create: `ScreenshotTool/InputMethod/TISInputSourceService.swift`
- Create: `ScreenshotTool/InputMethod/FrontmostApplicationObserver.swift`
- Create: `ScreenshotTool/InputMethod/WorkspaceFrontmostApplicationObserver.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodAutomationStatus.swift`
- Create: `ScreenshotTool/InputMethod/InputMethodManager.swift`
- Test: `ScreenshotToolTests/InputMethod/InputMethodManagerTests.swift`

- [ ] **Step 1: Write failing manager tests**

```swift
import XCTest
@testable import ScreenshotTool

final class InputMethodManagerTests: XCTestCase {
    @MainActor
    func testHandleFrontmostApplicationChangeAppliesMatchingRule() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateInputMethod {
            $0.isEnabled = true
            $0.globalDefaultInputSourceID = "com.apple.keylayout.ABC"
        }

        let rulesURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: rulesURL)
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        try rulesStore.upsert(
            AppInputMethodRule(
                id: UUID(),
                bundleIdentifier: "com.apple.Terminal",
                appName: "Terminal",
                inputSourceID: "com.apple.keylayout.US",
                isEnabled: true
            )
        )

        let service = FakeInputSourceService(current: "com.apple.keylayout.ABC")
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: service,
            matcher: InputMethodRuleMatcher()
        )

        manager.handleFrontmostApplicationChange(bundleIdentifier: "com.apple.Terminal")

        XCTAssertEqual(service.selectedIDs, ["com.apple.keylayout.US"])
        XCTAssertEqual(manager.status.lastTargetInputSourceID, "com.apple.keylayout.US")
        XCTAssertEqual(manager.status.lastSwitchSucceeded, true)
    }
}

private final class FakeInputSourceService: InputSourceService {
    var current: String?
    var selectedIDs: [String] = []

    init(current: String?) {
        self.current = current
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        []
    }

    func currentInputSourceID() -> String? {
        current
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        selectedIDs.append(id)
        current = id
        return true
    }
}
```

- [ ] **Step 2: Run the manager test to verify it fails**

Run: `make test-only TEST=ScreenshotToolTests/InputMethodManagerTests/testHandleFrontmostApplicationChangeAppliesMatchingRule`

Expected: FAIL with `Cannot find type 'InputSourceService' in scope`

- [ ] **Step 3: Implement the manager and macOS adapters**

```swift
import Foundation

protocol InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor]
    func currentInputSourceID() -> String?
    @discardableResult
    func selectInputSource(id: String) -> Bool
}
```

```swift
import Carbon
import Foundation

final class TISInputSourceService: InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor] {
        guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return list.compactMap { source in
            guard
                let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                let namePointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
            else {
                return nil
            }

            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
            let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue() as String
            return InputSourceDescriptor(id: id, localizedName: name)
        }
    }

    func currentInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        guard
            let list = TISCreateInputSourceList([kTISPropertyInputSourceID: id] as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource],
            let source = list.first
        else {
            return false
        }

        return TISSelectInputSource(source) == noErr
    }
}
```

```swift
import Foundation

protocol FrontmostApplicationObserver: AnyObject {
    var onChange: ((String?) -> Void)? { get set }
    func start()
    func stop()
}
```

```swift
import AppKit
import Foundation

final class WorkspaceFrontmostApplicationObserver: FrontmostApplicationObserver {
    var onChange: ((String?) -> Void)?
    private var token: NSObjectProtocol?

    func start() {
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.onChange?(app?.bundleIdentifier)
        }
    }

    func stop() {
        if let token {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        token = nil
    }
}
```

```swift
import Foundation

struct InputMethodAutomationStatus: Equatable {
    var lastBundleIdentifier: String?
    var lastTargetInputSourceID: String?
    var lastSwitchSucceeded: Bool?
}
```

```swift
import Foundation

@MainActor
final class InputMethodManager: ObservableObject {
    private let preferencesStore: AppPreferencesStore
    private let rulesStore: InputMethodRulesStore
    private let inputSourceService: InputSourceService
    private let matcher: InputMethodRuleMatcher
    private weak var observer: FrontmostApplicationObserver?

    @Published private(set) var status = InputMethodAutomationStatus()

    init(
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        inputSourceService: InputSourceService,
        matcher: InputMethodRuleMatcher,
        observer: FrontmostApplicationObserver? = nil
    ) {
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.inputSourceService = inputSourceService
        self.matcher = matcher
        self.observer = observer
    }

    func startObserving() {
        observer?.onChange = { [weak self] bundleIdentifier in
            Task { @MainActor in
                self?.handleFrontmostApplicationChange(bundleIdentifier: bundleIdentifier)
            }
        }
        observer?.start()
    }

    func stopObserving() {
        observer?.stop()
    }

    func handleFrontmostApplicationChange(bundleIdentifier: String?) {
        let resolution = matcher.resolve(
            bundleIdentifier: bundleIdentifier,
            preferences: preferencesStore.inputMethodPreferences,
            rules: rulesStore.rules
        )

        guard let target = resolution.targetInputSourceID else {
            status = InputMethodAutomationStatus(
                lastBundleIdentifier: bundleIdentifier,
                lastTargetInputSourceID: nil,
                lastSwitchSucceeded: nil
            )
            return
        }

        if inputSourceService.currentInputSourceID() == target {
            status = InputMethodAutomationStatus(
                lastBundleIdentifier: bundleIdentifier,
                lastTargetInputSourceID: target,
                lastSwitchSucceeded: true
            )
            return
        }

        let succeeded = inputSourceService.selectInputSource(id: target)
        status = InputMethodAutomationStatus(
            lastBundleIdentifier: bundleIdentifier,
            lastTargetInputSourceID: target,
            lastSwitchSucceeded: succeeded
        )
    }
}
```

- [ ] **Step 4: Run the manager test to verify it passes**

Run: `make test-only TEST=ScreenshotToolTests/InputMethodManagerTests/testHandleFrontmostApplicationChangeAppliesMatchingRule`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/InputMethod ScreenshotToolTests/InputMethod/InputMethodManagerTests.swift
git commit -m "feat: add input method automation manager"
```

## Task 5: Build the Main Window, Settings UI, Permissions, and Login-Item Plumbing

**Files:**
- Create: `ScreenshotTool/Support/Permissions/PermissionsService.swift`
- Create: `ScreenshotTool/Support/Permissions/DefaultPermissionsService.swift`
- Create: `ScreenshotTool/Support/LoginItemService.swift`
- Create: `ScreenshotTool/Support/SystemLoginItemService.swift`
- Create: `ScreenshotTool/App/WindowRouter.swift`
- Create: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
- Create: `ScreenshotTool/Features/Main/MainWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/SettingsWindowViewModel.swift`
- Create: `ScreenshotTool/Features/Settings/SettingsWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/GeneralSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/ScreenshotSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/AnnotationSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/InputMethodSettingsView.swift`
- Modify: `ScreenshotTool/App/ScreenshotToolApp.swift`
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Test: `ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift`

- [ ] **Step 1: Write failing settings view-model tests**

```swift
import XCTest
@testable import ScreenshotTool

final class SettingsWindowViewModelTests: XCTestCase {
    @MainActor
    func testSetLaunchAtLoginPersistsAndCallsService() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
        let loginItemService = FakeLoginItemService()
        let permissionsService = FakePermissionsService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            matcher: InputMethodRuleMatcher()
        )

        let viewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            permissionsService: permissionsService,
            loginItemService: loginItemService,
            inputMethodManager: manager
        )

        try viewModel.setLaunchAtLogin(true)

        XCTAssertTrue(preferencesStore.appPreferences.launchAtLogin)
        XCTAssertEqual(loginItemService.lastSetValue, true)
    }
}

private final class FakeLoginItemService: LoginItemService {
    var lastSetValue: Bool?

    func currentStatus() -> Bool {
        false
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        lastSetValue = enabled
    }
}

private struct FakePermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .unknown, accessibility: .unknown)
    }

    func openScreenRecordingSettings() {}
    func openAccessibilitySettings() {}
}

private final class FakeSettingsInputSourceService: InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor] {
        [InputSourceDescriptor(id: "com.apple.keylayout.ABC", localizedName: "ABC")]
    }

    func currentInputSourceID() -> String? {
        "com.apple.keylayout.ABC"
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        true
    }
}
```

- [ ] **Step 2: Run the settings test to verify it fails**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowViewModelTests`

Expected: FAIL with `Cannot find 'SettingsWindowViewModel' in scope`

- [ ] **Step 3: Implement services, router, view models, and sectioned settings UI**

```swift
import Foundation

enum PermissionState: Equatable {
    case unknown
    case granted
    case denied
}

struct PermissionsSnapshot: Equatable {
    var screenRecording: PermissionState
    var accessibility: PermissionState
}

protocol PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot
    func openScreenRecordingSettings()
    func openAccessibilitySettings()
}
```

```swift
import AppKit
import ApplicationServices
import Foundation

struct DefaultPermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(
            screenRecording: CGPreflightScreenCaptureAccess() ? .granted : .unknown,
            accessibility: AXIsProcessTrusted() ? .granted : .unknown
        )
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
```

```swift
import Foundation

protocol LoginItemService {
    func currentStatus() -> Bool
    func setLaunchAtLogin(_ enabled: Bool) throws
}
```

```swift
import Foundation
import ServiceManagement

struct SystemLoginItemService: LoginItemService {
    func currentStatus() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

```swift
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
```

```swift
import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter

    @Published private(set) var permissions: PermissionsSnapshot

    init(permissionsService: PermissionsService, windowRouter: WindowRouter) {
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.permissions = permissionsService.currentSnapshot()
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
    }

    func openSettings() {
        windowRouter.openSettings()
    }
}
```

```swift
import Foundation

@MainActor
final class SettingsWindowViewModel: ObservableObject {
    private let preferencesStore: AppPreferencesStore
    private let rulesStore: InputMethodRulesStore
    private let inputSourceService: InputSourceService
    private let permissionsService: PermissionsService
    private let loginItemService: LoginItemService
    private let inputMethodManager: InputMethodManager

    @Published private(set) var appPreferences: AppPreferences
    @Published private(set) var capturePreferences: CapturePreferences
    @Published private(set) var annotationPreferences: AnnotationPreferences
    @Published private(set) var inputMethodPreferences: InputMethodPreferences
    @Published private(set) var rules: [AppInputMethodRule]
    @Published private(set) var availableInputSources: [InputSourceDescriptor]
    @Published private(set) var permissionSnapshot: PermissionsSnapshot

    init(
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        inputSourceService: InputSourceService,
        permissionsService: PermissionsService,
        loginItemService: LoginItemService,
        inputMethodManager: InputMethodManager
    ) {
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.inputSourceService = inputSourceService
        self.permissionsService = permissionsService
        self.loginItemService = loginItemService
        self.inputMethodManager = inputMethodManager
        self.appPreferences = preferencesStore.appPreferences
        self.capturePreferences = preferencesStore.capturePreferences
        self.annotationPreferences = preferencesStore.annotationPreferences
        self.inputMethodPreferences = preferencesStore.inputMethodPreferences
        self.rules = rulesStore.rules
        self.availableInputSources = inputSourceService.availableInputSources()
        self.permissionSnapshot = permissionsService.currentSnapshot()
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        try loginItemService.setLaunchAtLogin(enabled)
        preferencesStore.updateApp { $0.launchAtLogin = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setMenuBarIconVisible(_ enabled: Bool) {
        preferencesStore.updateApp { $0.showsMenuBarIcon = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setStayResident(_ enabled: Bool) {
        preferencesStore.updateApp { $0.stayResidentAfterClosingWindow = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setDefaultOutputAction(_ action: CaptureOutputAction) {
        preferencesStore.updateCapture { $0.defaultOutputAction = action }
        capturePreferences = preferencesStore.capturePreferences
    }

    func setAnnotationLineWidth(_ width: Double) {
        preferencesStore.updateAnnotation { $0.defaultLineWidth = width }
        annotationPreferences = preferencesStore.annotationPreferences
    }

    func setInputMethodEnabled(_ enabled: Bool) {
        preferencesStore.updateInputMethod { $0.isEnabled = enabled }
        inputMethodPreferences = preferencesStore.inputMethodPreferences
    }

    func setGlobalInputSourceID(_ id: String?) {
        preferencesStore.updateInputMethod { $0.globalDefaultInputSourceID = id }
        inputMethodPreferences = preferencesStore.inputMethodPreferences
    }

    func addRule(bundleIdentifier: String, appName: String, inputSourceID: String) throws {
        let rule = AppInputMethodRule(
            id: UUID(),
            bundleIdentifier: bundleIdentifier,
            appName: appName,
            inputSourceID: inputSourceID,
            isEnabled: true
        )
        try rulesStore.upsert(rule)
        rules = rulesStore.rules
    }

    func removeRule(id: UUID) throws {
        try rulesStore.remove(id: id)
        rules = rulesStore.rules
    }
}
```

```swift
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screenshot Tool")
                .font(.largeTitle)
            Text("Screen Recording: \(String(describing: viewModel.permissions.screenRecording))")
            Text("Accessibility: \(String(describing: viewModel.permissions.accessibility))")
            Button("Open Settings") {
                viewModel.openSettings()
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
        .onAppear {
            viewModel.refresh()
        }
    }
}
```

```swift
import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Text("General") }
            ScreenshotSettingsView(viewModel: viewModel)
                .tabItem { Text("Screenshot") }
            AnnotationSettingsView(viewModel: viewModel)
                .tabItem { Text("Annotation") }
            InputMethodSettingsView(viewModel: viewModel)
                .tabItem { Text("Input Method") }
        }
        .frame(width: 720, height: 520)
    }
}
```

```swift
import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Toggle("Stay resident after closing windows", isOn: Binding(
                get: { viewModel.appPreferences.stayResidentAfterClosingWindow },
                set: viewModel.setStayResident
            ))
            Toggle("Show menu bar icon", isOn: Binding(
                get: { viewModel.appPreferences.showsMenuBarIcon },
                set: viewModel.setMenuBarIconVisible
            ))
        }
        .padding(24)
    }
}
```

```swift
import SwiftUI

struct ScreenshotSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Picker("Default action", selection: Binding(
                get: { viewModel.capturePreferences.defaultOutputAction },
                set: viewModel.setDefaultOutputAction
            )) {
                ForEach(CaptureOutputAction.allCases, id: \.self) { action in
                    Text(action.rawValue).tag(action)
                }
            }
        }
        .padding(24)
    }
}
```

```swift
import SwiftUI

struct AnnotationSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Slider(
                value: Binding(
                    get: { viewModel.annotationPreferences.defaultLineWidth },
                    set: viewModel.setAnnotationLineWidth
                ),
                in: 1...12
            ) {
                Text("Default line width")
            }
        }
        .padding(24)
    }
}
```

```swift
import SwiftUI

struct InputMethodSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel
    @State private var bundleIdentifier = ""
    @State private var appName = ""
    @State private var inputSourceID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable input method automation", isOn: Binding(
                get: { viewModel.inputMethodPreferences.isEnabled },
                set: viewModel.setInputMethodEnabled
            ))
            Picker("Global default input source", selection: Binding(
                get: { viewModel.inputMethodPreferences.globalDefaultInputSourceID ?? "" },
                set: { value in
                    viewModel.setGlobalInputSourceID(value.isEmpty ? nil : value)
                }
            )) {
                Text("None").tag("")
                ForEach(viewModel.availableInputSources) { source in
                    Text(source.localizedName).tag(source.id)
                }
            }
            List(viewModel.rules) { rule in
                HStack {
                    Text(rule.appName)
                    Spacer()
                    Text(rule.inputSourceID)
                }
            }
            HStack {
                TextField("Bundle ID", text: $bundleIdentifier)
                TextField("App Name", text: $appName)
                TextField("Input Source ID", text: $inputSourceID)
                Button("Add Rule") {
                    try? viewModel.addRule(bundleIdentifier: bundleIdentifier, appName: appName, inputSourceID: inputSourceID)
                    bundleIdentifier = ""
                    appName = ""
                    inputSourceID = ""
                }
            }
        }
        .padding(24)
    }
}
```

```swift
import SwiftUI

@main
struct ScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup(environment.windowTitle) {
            MainWindowView(viewModel: environment.mainWindowViewModel)
        }
        Settings {
            SettingsWindowView(viewModel: environment.settingsWindowViewModel)
        }
    }
}
```

```swift
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String
    let preferencesStore: AppPreferencesStore
    let rulesStore: InputMethodRulesStore
    let permissionsService: PermissionsService
    let loginItemService: LoginItemService
    let inputSourceService: InputSourceService
    let inputMethodManager: InputMethodManager
    let windowRouter: WindowRouter
    let mainWindowViewModel: MainWindowViewModel
    let settingsWindowViewModel: SettingsWindowViewModel

    init(
        windowTitle: String = "Screenshot Tool",
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        permissionsService: PermissionsService,
        loginItemService: LoginItemService,
        inputSourceService: InputSourceService,
        inputMethodManager: InputMethodManager,
        windowRouter: WindowRouter
    ) {
        self.windowTitle = windowTitle
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.permissionsService = permissionsService
        self.loginItemService = loginItemService
        self.inputSourceService = inputSourceService
        self.inputMethodManager = inputMethodManager
        self.windowRouter = windowRouter
        self.mainWindowViewModel = MainWindowViewModel(
            permissionsService: permissionsService,
            windowRouter: windowRouter
        )
        self.settingsWindowViewModel = SettingsWindowViewModel(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            permissionsService: permissionsService,
            loginItemService: loginItemService,
            inputMethodManager: inputMethodManager
        )
    }

    static func bootstrap() -> AppEnvironment {
        let preferencesStore = AppPreferencesStore()
        let rulesURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenshotTool/input-method-rules.json")
        let rulesStore = InputMethodRulesStore(fileURL: rulesURL)
        let inputSourceService = TISInputSourceService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher(),
            observer: WorkspaceFrontmostApplicationObserver()
        )
        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: WindowRouter()
        )
    }

    static func bootstrapForTests() -> AppEnvironment {
        let defaults = UserDefaults(suiteName: "ScreenshotToolTests")!
        defaults.removePersistentDomain(forName: "ScreenshotToolTests")
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("rules-tests.json"))
        let inputSourceService = TISInputSourceService()
        let manager = InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: inputSourceService,
            matcher: InputMethodRuleMatcher()
        )
        return AppEnvironment(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            permissionsService: DefaultPermissionsService(),
            loginItemService: SystemLoginItemService(),
            inputSourceService: inputSourceService,
            inputMethodManager: manager,
            windowRouter: WindowRouter()
        )
    }
}
```

- [ ] **Step 4: Run the settings test to verify it passes**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowViewModelTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Support ScreenshotTool/App/WindowRouter.swift ScreenshotTool/Features ScreenshotTool/App/ScreenshotToolApp.swift ScreenshotTool/App/AppEnvironment.swift ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift
git commit -m "feat: add app shell settings and system services"
```

## Task 6: Build Capture Selection, Screenshot Service, and Coordinator

**Files:**
- Create: `ScreenshotTool/Capture/CaptureSelection.swift`
- Create: `ScreenshotTool/Capture/CaptureResult.swift`
- Create: `ScreenshotTool/Capture/ScreenCaptureService.swift`
- Create: `ScreenshotTool/Capture/WindowListScreenCaptureService.swift`
- Create: `ScreenshotTool/Capture/CaptureCoordinator.swift`
- Test: `ScreenshotToolTests/Capture/CaptureSelectionTests.swift`
- Test: `ScreenshotToolTests/Capture/CaptureCoordinatorTests.swift`

- [ ] **Step 1: Write failing selection and coordinator tests**

```swift
import XCTest
@testable import ScreenshotTool

final class CaptureSelectionTests: XCTestCase {
    func testNormalizedRectUsesMinimumOriginAndAbsoluteSize() {
        let selection = CaptureSelection(start: CGPoint(x: 300, y: 400), end: CGPoint(x: 120, y: 220))

        XCTAssertEqual(selection.normalizedRect, CGRect(x: 120, y: 220, width: 180, height: 180))
    }
}
```

```swift
import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureCoordinatorTests: XCTestCase {
    @MainActor
    func testCompleteSelectionCapturesImageAndPublishesResult() async throws {
        let service = FakeScreenCaptureService()
        let coordinator = CaptureCoordinator(screenCaptureService: service)
        coordinator.beginCapture()
        coordinator.updateSelection(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 110, y: 60))

        try await coordinator.completeSelection()

        XCTAssertEqual(service.capturedRects, [CGRect(x: 10, y: 10, width: 100, height: 50)])
        XCTAssertEqual(coordinator.lastResult?.selectionRect, CGRect(x: 10, y: 10, width: 100, height: 50))
        XCTAssertFalse(coordinator.isCapturing)
    }
}

private final class FakeScreenCaptureService: ScreenCaptureService {
    var capturedRects: [CGRect] = []

    func capture(rect: CGRect) throws -> CGImage {
        capturedRects.append(rect)
        return CGImage(
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(.premultipliedLast),
            provider: CGDataProvider(data: Data(repeating: 255, count: 16) as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}
```

- [ ] **Step 2: Run the capture tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/CaptureSelectionTests`

Expected: FAIL with `Cannot find 'CaptureSelection' in scope`

Run: `make test-only TEST=ScreenshotToolTests/CaptureCoordinatorTests`

Expected: FAIL with `Cannot find type 'ScreenCaptureService' in scope`

- [ ] **Step 3: Implement capture geometry, result type, service protocol, and coordinator**

```swift
import CoreGraphics
import Foundation

struct CaptureSelection: Equatable {
    let start: CGPoint
    let end: CGPoint

    var normalizedRect: CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
```

```swift
import CoreGraphics
import Foundation

struct CaptureResult {
    let image: CGImage
    let selectionRect: CGRect
    let capturedAt: Date
}
```

```swift
import CoreGraphics
import Foundation

protocol ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage
}
```

```swift
import CoreGraphics
import Foundation

enum ScreenCaptureError: Error {
    case captureFailed
}

struct WindowListScreenCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        guard let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            throw ScreenCaptureError.captureFailed
        }
        return image
    }
}
```

```swift
import Foundation

@MainActor
final class CaptureCoordinator: ObservableObject {
    private let screenCaptureService: ScreenCaptureService

    @Published private(set) var isCapturing = false
    @Published private(set) var currentSelection: CaptureSelection?
    @Published private(set) var lastResult: CaptureResult?

    var onCaptureStarted: (() -> Void)?
    var onCaptureCancelled: (() -> Void)?
    var onCaptureCompleted: ((CaptureResult) -> Void)?

    init(screenCaptureService: ScreenCaptureService) {
        self.screenCaptureService = screenCaptureService
    }

    func beginCapture() {
        isCapturing = true
        currentSelection = nil
        onCaptureStarted?()
    }

    func updateSelection(start: CGPoint, end: CGPoint) {
        currentSelection = CaptureSelection(start: start, end: end)
    }

    func cancelCapture() {
        isCapturing = false
        currentSelection = nil
        onCaptureCancelled?()
    }

    func completeSelection() async throws {
        guard let selection = currentSelection else {
            return
        }

        let rect = selection.normalizedRect
        let image = try screenCaptureService.capture(rect: rect)
        let result = CaptureResult(image: image, selectionRect: rect, capturedAt: Date())

        lastResult = result
        currentSelection = nil
        isCapturing = false
        onCaptureCompleted?(result)
    }
}
```

- [ ] **Step 4: Run the capture tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/CaptureSelectionTests`

Expected: PASS

Run: `make test-only TEST=ScreenshotToolTests/CaptureCoordinatorTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Capture ScreenshotToolTests/Capture/CaptureSelectionTests.swift ScreenshotToolTests/Capture/CaptureCoordinatorTests.swift
git commit -m "feat: add capture coordinator core"
```

## Task 7: Add Global Hotkeys, Overlay Windows, and Menu Bar Control

**Files:**
- Create: `ScreenshotTool/Capture/Hotkeys/HotkeyService.swift`
- Create: `ScreenshotTool/Capture/Hotkeys/CarbonHotkeyService.swift`
- Create: `ScreenshotTool/App/CaptureHotkeyHandler.swift`
- Create: `ScreenshotTool/App/MenuBarController.swift`
- Create: `ScreenshotTool/Capture/Overlay/CaptureOverlayWindow.swift`
- Create: `ScreenshotTool/Capture/Overlay/CaptureOverlayView.swift`
- Modify: `ScreenshotTool/App/AppDelegate.swift`
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Modify: `ScreenshotTool/App/WindowRouter.swift`
- Test: `ScreenshotToolTests/Capture/CaptureHotkeyHandlerTests.swift`

- [ ] **Step 1: Write the failing hotkey handler test**

```swift
import XCTest
@testable import ScreenshotTool

final class CaptureHotkeyHandlerTests: XCTestCase {
    @MainActor
    func testStartRegistersConfiguredHotkey() throws {
        let hotkeyService = FakeHotkeyService()
        let coordinator = CaptureCoordinator(screenCaptureService: FakeCoordinatorCaptureService())
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let handler = CaptureHotkeyHandler(
            hotkeyService: hotkeyService,
            preferencesStore: preferencesStore,
            captureCoordinator: coordinator
        )

        try handler.start()

        XCTAssertEqual(hotkeyService.registeredHotkey, .defaultCapture)
    }
}

private final class FakeHotkeyService: HotkeyService {
    var registeredHotkey: GlobalHotkey?

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        registeredHotkey = hotkey
    }

    func unregisterAll() {}
}

private struct FakeCoordinatorCaptureService: ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        fatalError("Not needed for this test")
    }
}
```

- [ ] **Step 2: Run the hotkey test to verify it fails**

Run: `make test-only TEST=ScreenshotToolTests/CaptureHotkeyHandlerTests`

Expected: FAIL with `Cannot find type 'HotkeyService' in scope`

- [ ] **Step 3: Implement hotkey registration, overlay UI, and menu bar visibility control**

```swift
import Foundation

protocol HotkeyService {
    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws
    func unregisterAll()
}
```

```swift
import Carbon
import Foundation

final class CarbonHotkeyService: HotkeyService {
    private var handlers: [UInt32: () -> Void] = [:]
    private var hotKeyRefs: [EventHotKeyRef] = []

    func register(hotkey: GlobalHotkey, handler: @escaping () -> Void) throws {
        handlers[hotkey.keyCode] = handler
    }

    func unregisterAll() {
        handlers.removeAll()
        hotKeyRefs.removeAll()
    }
}
```

```swift
import Foundation

@MainActor
final class CaptureHotkeyHandler {
    private let hotkeyService: HotkeyService
    private let preferencesStore: AppPreferencesStore
    private let captureCoordinator: CaptureCoordinator

    init(
        hotkeyService: HotkeyService,
        preferencesStore: AppPreferencesStore,
        captureCoordinator: CaptureCoordinator
    ) {
        self.hotkeyService = hotkeyService
        self.preferencesStore = preferencesStore
        self.captureCoordinator = captureCoordinator
    }

    func start() throws {
        try hotkeyService.register(hotkey: preferencesStore.capturePreferences.hotkey) { [weak captureCoordinator] in
            Task { @MainActor in
                captureCoordinator?.beginCapture()
            }
        }
    }

    func reload() throws {
        hotkeyService.unregisterAll()
        try start()
    }
}
```

```swift
import AppKit
import Foundation

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private let openSettings: () -> Void
    private let startCapture: () -> Void

    init(openSettings: @escaping () -> Void, startCapture: @escaping () -> Void) {
        self.openSettings = openSettings
        self.startCapture = startCapture
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                item.button?.title = "Shot"
                let menu = NSMenu()
                menu.addItem(withTitle: "Capture", action: #selector(handleCapture), keyEquivalent: "")
                menu.addItem(withTitle: "Settings", action: #selector(handleSettings), keyEquivalent: "")
                item.menu = menu
                statusItem = item
            }
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc private func handleCapture() {
        startCapture()
    }

    @objc private func handleSettings() {
        openSettings()
    }
}
```

```swift
import AppKit

final class CaptureOverlayWindow: NSWindow {
    init(contentView: NSView, frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.ignoresMouseEvents = false
    }
}
```

```swift
import AppKit

final class CaptureOverlayView: NSView {
    var onSelectionChanged: ((CGPoint, CGPoint) -> Void)?
    var onSelectionCompleted: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var dragStart: CGPoint?

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        if let dragStart {
            onSelectionChanged?(dragStart, dragStart)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
        onSelectionChanged?(dragStart, current)
    }

    override func mouseUp(with event: NSEvent) {
        onSelectionCompleted?()
        dragStart = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancelled?()
        }
    }
}
```

```swift
import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    private var overlayWindows: [CaptureOverlayWindow] = []

    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func showCaptureOverlay(
        onSelectionChanged: @escaping (CGPoint, CGPoint) -> Void,
        onSelectionCompleted: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) {
        hideCaptureOverlay()
        overlayWindows = NSScreen.screens.map { screen in
            let view = CaptureOverlayView(frame: screen.frame)
            view.onSelectionChanged = onSelectionChanged
            view.onSelectionCompleted = onSelectionCompleted
            view.onCancelled = onCancelled
            let window = CaptureOverlayWindow(contentView: view, frame: screen.frame)
            window.makeKeyAndOrderFront(nil)
            return window
        }
    }

    func hideCaptureOverlay() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }
}
```

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(environment?.preferencesStore.appPreferences.stayResidentAfterClosingWindow ?? true)
    }
}
```

```swift
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String
    let preferencesStore: AppPreferencesStore
    let rulesStore: InputMethodRulesStore
    let permissionsService: PermissionsService
    let loginItemService: LoginItemService
    let inputSourceService: InputSourceService
    let inputMethodManager: InputMethodManager
    let windowRouter: WindowRouter
    let captureCoordinator: CaptureCoordinator
    let hotkeyHandler: CaptureHotkeyHandler
    let menuBarController: MenuBarController
    let mainWindowViewModel: MainWindowViewModel
    let settingsWindowViewModel: SettingsWindowViewModel

    func start() {
        inputMethodManager.startObserving()
        try? hotkeyHandler.start()
        menuBarController.setVisible(preferencesStore.appPreferences.showsMenuBarIcon)
        captureCoordinator.onCaptureStarted = { [weak windowRouter, weak captureCoordinator] in
            guard let coordinator = captureCoordinator else { return }
            windowRouter?.showCaptureOverlay(
                onSelectionChanged: { start, end in
                    coordinator.updateSelection(start: start, end: end)
                },
                onSelectionCompleted: {
                    Task { @MainActor in
                        try? await coordinator.completeSelection()
                    }
                },
                onCancelled: {
                    coordinator.cancelCapture()
                }
            )
        }
        captureCoordinator.onCaptureCancelled = { [weak windowRouter] in
            windowRouter?.hideCaptureOverlay()
        }
        captureCoordinator.onCaptureCompleted = { [weak windowRouter] _ in
            windowRouter?.hideCaptureOverlay()
        }
    }
}
```

- [ ] **Step 4: Run the hotkey test to verify it passes**

Run: `make test-only TEST=ScreenshotToolTests/CaptureHotkeyHandlerTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Capture/Hotkeys ScreenshotTool/App/CaptureHotkeyHandler.swift ScreenshotTool/App/MenuBarController.swift ScreenshotTool/Capture/Overlay ScreenshotTool/App/AppDelegate.swift ScreenshotTool/App/AppEnvironment.swift ScreenshotTool/App/WindowRouter.swift ScreenshotToolTests/Capture/CaptureHotkeyHandlerTests.swift
git commit -m "feat: add hotkeys and capture overlay shell"
```

## Task 8: Build Annotation Models, Renderer, and Toolbar Placement

**Files:**
- Create: `ScreenshotTool/Annotation/AnnotationTool.swift`
- Create: `ScreenshotTool/Annotation/AnnotationItem.swift`
- Create: `ScreenshotTool/Annotation/AnnotationDocument.swift`
- Create: `ScreenshotTool/Annotation/AnnotationRenderer.swift`
- Create: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarPlacement.swift`
- Test: `ScreenshotToolTests/Annotation/AnnotationDocumentTests.swift`
- Test: `ScreenshotToolTests/Annotation/FloatingToolbarPlacementTests.swift`

- [ ] **Step 1: Write failing annotation tests**

```swift
import XCTest
@testable import ScreenshotTool

final class AnnotationDocumentTests: XCTestCase {
    func testUndoRemovesLastAnnotationItem() {
        let document = AnnotationDocument()
        document.add(.rectangle(CGRect(x: 10, y: 10, width: 40, height: 30), "#FF3B30", 4))
        document.add(.text("Hello", CGPoint(x: 20, y: 20), "#111111", 14))

        document.undo()

        XCTAssertEqual(document.items.count, 1)
    }
}
```

```swift
import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class FloatingToolbarPlacementTests: XCTestCase {
    func testPlacementFlipsAboveSelectionWhenBottomSpaceIsInsufficient() {
        let placement = FloatingToolbarPlacement.resolve(
            selectionRect: CGRect(x: 100, y: 10, width: 160, height: 80),
            availableRect: CGRect(x: 0, y: 0, width: 400, height: 300),
            toolbarSize: CGSize(width: 220, height: 44)
        )

        XCTAssertLessThan(placement.origin.y, 100)
    }
}
```

- [ ] **Step 2: Run the annotation tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/AnnotationDocumentTests`

Expected: FAIL with `Cannot find 'AnnotationDocument' in scope`

Run: `make test-only TEST=ScreenshotToolTests/FloatingToolbarPlacementTests`

Expected: FAIL with `Cannot find 'FloatingToolbarPlacement' in scope`

- [ ] **Step 3: Implement annotation state and placement helpers**

```swift
import Foundation

enum AnnotationTool: String, CaseIterable {
    case rectangle
    case arrow
    case text
    case pen
    case blur
}
```

```swift
import CoreGraphics
import Foundation

enum AnnotationItem: Equatable {
    case rectangle(CGRect, String, Double)
    case arrow(CGPoint, CGPoint, String, Double)
    case text(String, CGPoint, String, Double)
    case pen([CGPoint], String, Double)
    case blur(CGRect, Double)
}
```

```swift
import Foundation

@MainActor
final class AnnotationDocument: ObservableObject {
    @Published private(set) var items: [AnnotationItem] = []

    func add(_ item: AnnotationItem) {
        items.append(item)
    }

    func undo() {
        _ = items.popLast()
    }

    func clear() {
        items.removeAll()
    }
}
```

```swift
import CoreGraphics
import CoreImage
import Foundation

struct AnnotationRenderer {
    func render(baseImage: CGImage, items: [AnnotationItem]) -> CGImage {
        let ciImage = CIImage(cgImage: baseImage)
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent) ?? baseImage
    }
}
```

```swift
import CoreGraphics
import Foundation

struct FloatingToolbarPlacement {
    static func resolve(selectionRect: CGRect, availableRect: CGRect, toolbarSize: CGSize) -> CGRect {
        let preferredY = selectionRect.maxY + 8
        if preferredY + toolbarSize.height <= availableRect.maxY {
            return CGRect(x: selectionRect.minX, y: preferredY, width: toolbarSize.width, height: toolbarSize.height)
        }

        let fallbackY = max(availableRect.minY, selectionRect.minY - toolbarSize.height - 8)
        return CGRect(x: selectionRect.minX, y: fallbackY, width: toolbarSize.width, height: toolbarSize.height)
    }
}
```

- [ ] **Step 4: Run the annotation tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/AnnotationDocumentTests`

Expected: PASS

Run: `make test-only TEST=ScreenshotToolTests/FloatingToolbarPlacementTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Annotation ScreenshotToolTests/Annotation/AnnotationDocumentTests.swift ScreenshotToolTests/Annotation/FloatingToolbarPlacementTests.swift
git commit -m "feat: add annotation document and toolbar placement"
```

## Task 9: Add Output Actions, History, Editor Window, Pin Window, and Floating Toolbar

**Files:**
- Create: `ScreenshotTool/Persistence/CaptureHistoryItem.swift`
- Create: `ScreenshotTool/Persistence/CaptureHistoryStore.swift`
- Create: `ScreenshotTool/Capture/ClipboardService.swift`
- Create: `ScreenshotTool/Capture/PasteboardClipboardService.swift`
- Create: `ScreenshotTool/Capture/CaptureOutputService.swift`
- Create: `ScreenshotTool/Annotation/AnnotationCanvasView.swift`
- Create: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarController.swift`
- Create: `ScreenshotTool/Annotation/Editor/EditorWindowController.swift`
- Create: `ScreenshotTool/Annotation/Pin/PinWindowController.swift`
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Modify: `ScreenshotTool/App/WindowRouter.swift`
- Modify: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
- Modify: `ScreenshotTool/Features/Main/MainWindowView.swift`
- Test: `ScreenshotToolTests/Persistence/CaptureHistoryStoreTests.swift`
- Test: `ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift`
- Test: `ScreenshotToolTests/Features/MainWindowViewModelTests.swift`

- [ ] **Step 1: Write failing history and output tests**

```swift
import XCTest
@testable import ScreenshotTool

final class CaptureHistoryStoreTests: XCTestCase {
    func testAppendTrimsItemsToConfiguredLimit() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: fileURL)
        let store = CaptureHistoryStore(fileURL: fileURL, limit: 2)

        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "a.png", savedFilePath: nil, didCopyToClipboard: true))
        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "b.png", savedFilePath: nil, didCopyToClipboard: true))
        try store.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "c.png", savedFilePath: nil, didCopyToClipboard: true))

        XCTAssertEqual(store.items.count, 2)
    }
}
```

```swift
import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureOutputServiceTests: XCTestCase {
    func testSaveWritesRenderedImageToConfiguredDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(#function)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let historyStore = CaptureHistoryStore(fileURL: directory.appendingPathComponent("history.json"), limit: 10)
        let clipboard = FakeClipboardService()
        let service = CaptureOutputService(
            renderer: AnnotationRenderer(),
            clipboardService: clipboard,
            historyStore: historyStore,
            cacheDirectory: directory
        )

        let result = CaptureResult(image: makeImage(), selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2), capturedAt: Date())
        let item = try service.save(
            result: result,
            document: AnnotationDocument(),
            format: .png,
            directory: directory
        )

        XCTAssertNotNil(item.savedFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath!))
        XCTAssertEqual(clipboard.copyCount, 0)
    }
}

private final class FakeClipboardService: ClipboardService {
    var copyCount = 0

    func copy(image: CGImage) {
        copyCount += 1
    }
}

private func makeImage() -> CGImage {
    CGImage(
        width: 2,
        height: 2,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(.premultipliedLast),
        provider: CGDataProvider(data: Data(repeating: 255, count: 16) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
```

```swift
import XCTest
@testable import ScreenshotTool

final class MainWindowViewModelTests: XCTestCase {
    @MainActor
    func testRefreshPullsLatestHistoryItems() throws {
        let permissionsService = FakePermissionsService()
        let router = WindowRouter()
        let historyURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: historyURL)
        let historyStore = CaptureHistoryStore(fileURL: historyURL, limit: 5)
        try historyStore.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "preview.png", savedFilePath: nil, didCopyToClipboard: true))

        let viewModel = MainWindowViewModel(
            permissionsService: permissionsService,
            windowRouter: router,
            historyStore: historyStore
        )

        viewModel.refresh()

        XCTAssertEqual(viewModel.recentCaptures.count, 1)
    }
}
```

- [ ] **Step 2: Run the history and output tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/CaptureHistoryStoreTests`

Expected: FAIL with `Cannot find 'CaptureHistoryStore' in scope`

Run: `make test-only TEST=ScreenshotToolTests/CaptureOutputServiceTests`

Expected: FAIL with `Cannot find type 'ClipboardService' in scope`

Run: `make test-only TEST=ScreenshotToolTests/MainWindowViewModelTests`

Expected: FAIL with `Extra argument 'historyStore' in call`

- [ ] **Step 3: Implement history, output services, annotation canvas, and output windows**

```swift
import Foundation

struct CaptureHistoryItem: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let previewFilePath: String
    let savedFilePath: String?
    let didCopyToClipboard: Bool
}
```

```swift
import Foundation

@MainActor
final class CaptureHistoryStore: ObservableObject {
    private let fileURL: URL
    private var limit: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var items: [CaptureHistoryItem]

    init(fileURL: URL, limit: Int) {
        self.fileURL = fileURL
        self.limit = limit
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([CaptureHistoryItem].self, from: data) {
            self.items = decoded
        } else {
            self.items = []
        }
    }

    func setLimit(_ limit: Int) throws {
        self.limit = limit
        try trimAndSave()
    }

    func append(_ item: CaptureHistoryItem) throws {
        items.insert(item, at: 0)
        try trimAndSave()
    }

    private func trimAndSave() throws {
        items = Array(items.prefix(limit))
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
```

```swift
import CoreGraphics
import Foundation

protocol ClipboardService {
    func copy(image: CGImage)
}
```

```swift
import AppKit
import CoreGraphics
import Foundation

struct PasteboardClipboardService: ClipboardService {
    func copy(image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: .zero)
        pasteboard.writeObjects([nsImage])
    }
}
```

```swift
import AppKit
import CoreGraphics
import Foundation

@MainActor
final class CaptureOutputService {
    private let renderer: AnnotationRenderer
    private let clipboardService: ClipboardService
    private let historyStore: CaptureHistoryStore
    private let cacheDirectory: URL

    init(
        renderer: AnnotationRenderer,
        clipboardService: ClipboardService,
        historyStore: CaptureHistoryStore,
        cacheDirectory: URL
    ) {
        self.renderer = renderer
        self.clipboardService = clipboardService
        self.historyStore = historyStore
        self.cacheDirectory = cacheDirectory
    }

    func copy(result: CaptureResult, document: AnnotationDocument) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        clipboardService.copy(image: rendered)
        let previewURL = try writePreview(rendered)
        let item = CaptureHistoryItem(
            id: UUID(),
            createdAt: result.capturedAt,
            previewFilePath: previewURL.path,
            savedFilePath: nil,
            didCopyToClipboard: true
        )
        try historyStore.append(item)
        return item
    }

    func save(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let savedURL = directory.appendingPathComponent("capture-\(UUID().uuidString).\(format == .png ? "png" : "jpg")")
        let nsImage = NSImage(cgImage: rendered, size: .zero)
        let representation = NSBitmapImageRep(data: nsImage.tiffRepresentation!)!
        let data = representation.representation(using: format == .png ? .png : .jpeg, properties: [:])!
        try data.write(to: savedURL, options: .atomic)

        let previewURL = try writePreview(rendered)
        let item = CaptureHistoryItem(
            id: UUID(),
            createdAt: result.capturedAt,
            previewFilePath: previewURL.path,
            savedFilePath: savedURL.path,
            didCopyToClipboard: false
        )
        try historyStore.append(item)
        return item
    }

    private func writePreview(_ image: CGImage) throws -> URL {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let previewURL = cacheDirectory.appendingPathComponent("preview-\(UUID().uuidString).png")
        let nsImage = NSImage(cgImage: image, size: .zero)
        let representation = NSBitmapImageRep(data: nsImage.tiffRepresentation!)!
        let data = representation.representation(using: .png, properties: [:])!
        try data.write(to: previewURL, options: .atomic)
        return previewURL
    }
}
```

```swift
import AppKit
import SwiftUI

struct AnnotationCanvasView: NSViewRepresentable {
    let image: CGImage
    @ObservedObject var document: AnnotationDocument

    func makeNSView(context: Context) -> NSImageView {
        NSImageView(image: NSImage(cgImage: image, size: .zero))
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(cgImage: image, size: .zero)
    }
}
```

```swift
import AppKit
import SwiftUI

@MainActor
final class FloatingToolbarController {
    private var panel: NSPanel?

    func show(frame: CGRect, copyAction: @escaping () -> Void, saveAction: @escaping () -> Void, pinAction: @escaping () -> Void, editAction: @escaping () -> Void) {
        let content = HStack {
            Button("Copy", action: copyAction)
            Button("Save", action: saveAction)
            Button("Pin", action: pinAction)
            Button("Edit", action: editAction)
        }
        .padding(10)

        let hosting = NSHostingView(rootView: content)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = hosting
        panel.level = .floating
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}
```

```swift
import AppKit
import SwiftUI

@MainActor
final class EditorWindowController {
    private var window: NSWindow?

    func show(result: CaptureResult, document: AnnotationDocument) {
        let view = AnnotationCanvasView(image: result.image, document: document)
        let hosting = NSHostingView(rootView: view.frame(minWidth: 800, minHeight: 600))
        let window = NSWindow(contentRect: CGRect(x: 120, y: 120, width: 900, height: 680), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.contentView = hosting
        window.title = "Screenshot Editor"
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
```

```swift
import AppKit

@MainActor
final class PinWindowController {
    private var windows: [NSWindow] = []

    func show(image: CGImage) {
        let imageView = NSImageView(image: NSImage(cgImage: image, size: .zero))
        let window = NSWindow(contentRect: CGRect(x: 160, y: 160, width: 360, height: 240), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.level = .floating
        window.contentView = imageView
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
}
```

```swift
import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter
    private let historyStore: CaptureHistoryStore

    @Published private(set) var permissions: PermissionsSnapshot
    @Published private(set) var recentCaptures: [CaptureHistoryItem] = []

    init(permissionsService: PermissionsService, windowRouter: WindowRouter, historyStore: CaptureHistoryStore) {
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.historyStore = historyStore
        self.permissions = permissionsService.currentSnapshot()
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
        recentCaptures = historyStore.items
    }

    func openSettings() {
        windowRouter.openSettings()
    }
}
```

```swift
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screenshot Tool")
                .font(.largeTitle)
            Text("Recent captures")
                .font(.headline)
            List(viewModel.recentCaptures) { item in
                VStack(alignment: .leading) {
                    Text(item.previewFilePath)
                    Text(item.savedFilePath ?? "Copied only")
                        .foregroundStyle(.secondary)
                }
            }
            Button("Open Settings") {
                viewModel.openSettings()
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
        .onAppear {
            viewModel.refresh()
        }
    }
}
```

```swift
import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    private var overlayWindows: [CaptureOverlayWindow] = []
    private let floatingToolbarController = FloatingToolbarController()
    private let editorWindowController = EditorWindowController()
    private let pinWindowController = PinWindowController()

    func presentFloatingToolbar(
        for result: CaptureResult,
        document: AnnotationDocument,
        outputService: CaptureOutputService,
        defaultSaveDirectory: URL,
        imageFormat: CaptureImageFormat
    ) {
        let frame = FloatingToolbarPlacement.resolve(
            selectionRect: result.selectionRect,
            availableRect: NSScreen.main?.visibleFrame ?? .zero,
            toolbarSize: CGSize(width: 260, height: 44)
        )

        floatingToolbarController.show(
            frame: frame,
            copyAction: { _ = try? outputService.copy(result: result, document: document) },
            saveAction: { _ = try? outputService.save(result: result, document: document, format: imageFormat, directory: defaultSaveDirectory) },
            pinAction: { pinWindowController.show(image: result.image) },
            editAction: { editorWindowController.show(result: result, document: document) }
        )
    }
}
```

```swift
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String
    let preferencesStore: AppPreferencesStore
    let rulesStore: InputMethodRulesStore
    let permissionsService: PermissionsService
    let loginItemService: LoginItemService
    let inputSourceService: InputSourceService
    let inputMethodManager: InputMethodManager
    let windowRouter: WindowRouter
    let captureCoordinator: CaptureCoordinator
    let hotkeyHandler: CaptureHotkeyHandler
    let menuBarController: MenuBarController
    let historyStore: CaptureHistoryStore
    let outputService: CaptureOutputService
    let mainWindowViewModel: MainWindowViewModel
    let settingsWindowViewModel: SettingsWindowViewModel

    func start() {
        inputMethodManager.startObserving()
        try? hotkeyHandler.start()
        menuBarController.setVisible(preferencesStore.appPreferences.showsMenuBarIcon)
        captureCoordinator.onCaptureStarted = { [weak windowRouter, weak captureCoordinator] in
            guard let coordinator = captureCoordinator else { return }
            windowRouter?.showCaptureOverlay(
                onSelectionChanged: { start, end in
                    coordinator.updateSelection(start: start, end: end)
                },
                onSelectionCompleted: {
                    Task { @MainActor in
                        try? await coordinator.completeSelection()
                    }
                },
                onCancelled: {
                    coordinator.cancelCapture()
                }
            )
        }
        captureCoordinator.onCaptureCancelled = { [weak windowRouter] in
            windowRouter?.hideCaptureOverlay()
        }
        captureCoordinator.onCaptureCompleted = { [weak self, weak windowRouter] result in
            guard let self else { return }
            windowRouter?.hideCaptureOverlay()
            let document = AnnotationDocument()
            let defaultDirectory = URL(fileURLWithPath: self.preferencesStore.capturePreferences.defaultSaveDirectoryPath ?? FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("ScreenshotTool").path)
            windowRouter?.presentFloatingToolbar(
                for: result,
                document: document,
                outputService: self.outputService,
                defaultSaveDirectory: defaultDirectory,
                imageFormat: self.preferencesStore.capturePreferences.imageFormat
            )
            self.mainWindowViewModel.refresh()
        }
    }
}
```

- [ ] **Step 4: Run the history and output tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/CaptureHistoryStoreTests`

Expected: PASS

Run: `make test-only TEST=ScreenshotToolTests/CaptureOutputServiceTests`

Expected: PASS

Run: `make test-only TEST=ScreenshotToolTests/MainWindowViewModelTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Persistence/CaptureHistoryItem.swift ScreenshotTool/Persistence/CaptureHistoryStore.swift ScreenshotTool/Capture/ClipboardService.swift ScreenshotTool/Capture/PasteboardClipboardService.swift ScreenshotTool/Capture/CaptureOutputService.swift ScreenshotTool/Annotation/AnnotationCanvasView.swift ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarController.swift ScreenshotTool/Annotation/Editor/EditorWindowController.swift ScreenshotTool/Annotation/Pin/PinWindowController.swift ScreenshotTool/App/AppEnvironment.swift ScreenshotTool/App/WindowRouter.swift ScreenshotTool/Features/Main/MainWindowViewModel.swift ScreenshotTool/Features/Main/MainWindowView.swift ScreenshotToolTests/Persistence/CaptureHistoryStoreTests.swift ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift ScreenshotToolTests/Features/MainWindowViewModelTests.swift
git commit -m "feat: add screenshot output flows and history"
```

## Manual Verification Checklist

After completing Task 9, run the full automated suite:

```bash
make test
```

Expected: `** TEST SUCCEEDED **`

Then perform this manual verification list in the built app:

1. Grant Screen Recording permission, trigger the global hotkey, and confirm the overlay appears on all attached displays.
2. Drag a capture selection, press `Esc`, and confirm the overlay closes without saving anything.
3. Drag a capture selection again and confirm the floating toolbar appears near the selection.
4. Use `Copy` and confirm the image pastes into Notes or Messages.
5. Use `Save` and confirm a file appears in the configured directory.
6. Use `Edit` and confirm a separate editor window opens.
7. Use `Pin` and confirm the pinned window stays floating above normal app windows.
8. Close the main window and confirm the app keeps responding to the capture hotkey if resident mode is enabled.
9. Toggle the menu bar icon off in settings and confirm the app still responds to the capture hotkey.
10. Set a global default input source, switch between two apps without app-specific rules, and confirm the global source is applied.
11. Add a per-app rule for `Terminal`, switch into `Terminal`, and confirm the per-app source overrides the global source.
12. Manually change the input source inside `Terminal`, remain in `Terminal`, and confirm the app does not immediately switch it back.
13. Leave `Terminal` and return to it, and confirm the app-specific rule is re-applied.

## Spec Coverage Notes

- Application shape is covered by Tasks 1, 5, and 7.
- Screenshot workflow is covered by Tasks 6, 7, 8, and 9.
- Input method workflow is covered by Tasks 3, 4, and 5.
- Settings structure is covered by Task 5.
- Capture history is covered by Task 9.
- Permission surfacing is covered by Task 5 plus the manual verification checklist.
- Non-goals such as OCR and scrolling capture are intentionally not scheduled.
