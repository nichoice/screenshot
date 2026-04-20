# macOS Screenshot Tool UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the app UI into a Chinese-first macOS 26 Liquid Glass experience with a tool-home main window, grouped-sidebar settings center, and stronger screenshot-time visual contrast.

**Architecture:** Keep existing product logic intact while introducing a shared appearance layer, a dedicated settings shell, a redesigned main window shell, and high-contrast screenshot chrome. The implementation should preserve the current working flows and tests, then layer visual structure and styling on top with minimal disruption to capture and input-method behavior.

**Tech Stack:** SwiftUI, AppKit, Observation/ObservableObject, XCTest, XcodeGen, macOS 26 SDK

---

## Planned File Structure

- Modify: `ScreenshotTool/Persistence/AppPreferences.swift`
  Theme mode enum and persisted appearance choice.
- Modify: `ScreenshotTool/Persistence/AppPreferencesStore.swift`
  Persist and update appearance preferences.
- Create: `ScreenshotTool/UI/AppTheme.swift`
  App-level appearance model and system mapping.
- Create: `ScreenshotTool/UI/AppThemeController.swift`
  Global theme resolver for light, dark, or follow-system.
- Create: `ScreenshotTool/UI/SettingsSidebarItem.swift`
  Sidebar navigation model for grouped settings.
- Create: `ScreenshotTool/UI/SettingsSectionCard.swift`
  Shared card container for right-side settings content.
- Create: `ScreenshotTool/UI/GlassSurface.swift`
  Shared Liquid Glass-friendly surface wrapper.
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
  Wire theme controller into window and settings view models.
- Modify: `ScreenshotTool/App/ScreenshotToolApp.swift`
  Apply app-wide appearance preferences to scenes.
- Modify: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
  Expose richer main-window status and quick actions state.
- Modify: `ScreenshotTool/Features/Main/MainWindowView.swift`
  Redesign main window as tool-home layout.
- Modify: `ScreenshotTool/Features/Settings/SettingsWindowViewModel.swift`
  Add sidebar selection, theme state, and richer page data.
- Modify: `ScreenshotTool/Features/Settings/SettingsWindowView.swift`
  Replace top tabs with grouped sidebar plus content layout.
- Modify: `ScreenshotTool/Features/Settings/GeneralSettingsView.swift`
  Rebuild as grouped cards.
- Create: `ScreenshotTool/Features/Settings/AppearanceSettingsView.swift`
  Global theme settings page.
- Modify: `ScreenshotTool/Features/Settings/ScreenshotSettingsView.swift`
  Richer screenshot preferences cards.
- Modify: `ScreenshotTool/Features/Settings/AnnotationSettingsView.swift`
  Richer annotation preferences cards.
- Modify: `ScreenshotTool/Features/Settings/InputMethodSettingsView.swift`
  Richer input-method rule management cards.
- Create: `ScreenshotTool/Features/Settings/DiagnosticsSettingsView.swift`
  Permissions and diagnostics page.
- Modify: `ScreenshotTool/Capture/Overlay/CaptureOverlayView.swift`
  High-contrast selection affordances.
- Modify: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarController.swift`
  High-contrast glass styling for floating toolbar.
- Create: `ScreenshotToolTests/UI/AppThemeControllerTests.swift`
- Create: `ScreenshotToolTests/Features/SettingsWindowLayoutTests.swift`
- Modify: `ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift`
- Modify: `ScreenshotToolTests/Features/MainWindowViewModelTests.swift`
- Create: `ScreenshotToolTests/Capture/CaptureOverlayContrastTests.swift`

## Task 1: Add App-Wide Theme Model and Persistence

**Files:**
- Create: `ScreenshotTool/UI/AppTheme.swift`
- Create: `ScreenshotTool/UI/AppThemeController.swift`
- Modify: `ScreenshotTool/Persistence/AppPreferences.swift`
- Modify: `ScreenshotTool/Persistence/AppPreferencesStore.swift`
- Test: `ScreenshotToolTests/UI/AppThemeControllerTests.swift`

- [ ] **Step 1: Write the failing theme tests**

```swift
import XCTest
@testable import ScreenshotTool

final class AppThemeControllerTests: XCTestCase {
    func testResolveExplicitDarkThemeReturnsDark() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.dark, systemIsDark: false), .dark)
    }

    func testResolveFollowSystemUsesSystemAppearance() {
        let controller = AppThemeController()

        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: true), .dark)
        XCTAssertEqual(controller.resolve(.followSystem, systemIsDark: false), .light)
    }
}
```

- [ ] **Step 2: Run the theme tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/AppThemeControllerTests`

Expected: FAIL with `Cannot find 'AppThemeController' in scope`

- [ ] **Step 3: Implement the minimal theme model and store support**

```swift
enum AppThemePreference: String, Codable, CaseIterable {
    case light
    case dark
    case followSystem
}
```

```swift
enum ResolvedAppTheme: Equatable {
    case light
    case dark
}
```

```swift
struct AppThemeController {
    func resolve(_ preference: AppThemePreference, systemIsDark: Bool) -> ResolvedAppTheme {
        switch preference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .followSystem:
            return systemIsDark ? .dark : .light
        }
    }
}
```

- [ ] **Step 4: Run the theme tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/AppThemeControllerTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/UI ScreenshotTool/Persistence/AppPreferences.swift ScreenshotTool/Persistence/AppPreferencesStore.swift ScreenshotToolTests/UI/AppThemeControllerTests.swift
git commit -m "feat: add app-wide theme preferences"
```

## Task 2: Rebuild Settings Window Shell Into Grouped Sidebar Layout

**Files:**
- Create: `ScreenshotTool/UI/SettingsSidebarItem.swift`
- Create: `ScreenshotTool/UI/SettingsSectionCard.swift`
- Create: `ScreenshotTool/UI/GlassSurface.swift`
- Modify: `ScreenshotTool/Features/Settings/SettingsWindowViewModel.swift`
- Modify: `ScreenshotTool/Features/Settings/SettingsWindowView.swift`
- Create: `ScreenshotTool/Features/Settings/AppearanceSettingsView.swift`
- Create: `ScreenshotTool/Features/Settings/DiagnosticsSettingsView.swift`
- Test: `ScreenshotToolTests/Features/SettingsWindowLayoutTests.swift`

- [ ] **Step 1: Write the failing settings shell tests**

```swift
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
```

- [ ] **Step 2: Run the settings shell tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowLayoutTests`

Expected: FAIL with `Cannot find 'SettingsSidebarItem' in scope`

- [ ] **Step 3: Implement the minimal grouped-sidebar shell**

```swift
struct SettingsSidebarItem: Equatable, Identifiable {
    let id: String
    let title: String
    let groupTitle: String

    static let defaultItems: [SettingsSidebarItem] = [
        .init(id: "general", title: "通用", groupTitle: "基础"),
        .init(id: "appearance", title: "外观", groupTitle: "基础"),
        .init(id: "capture", title: "截图", groupTitle: "截图"),
        .init(id: "annotation", title: "标注", groupTitle: "截图"),
        .init(id: "input-method", title: "输入法规则", groupTitle: "输入法"),
        .init(id: "diagnostics", title: "权限与诊断", groupTitle: "其他")
    ]
}
```

- [ ] **Step 4: Run the settings shell tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowLayoutTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/UI ScreenshotTool/Features/Settings ScreenshotToolTests/Features/SettingsWindowLayoutTests.swift
git commit -m "feat: rebuild settings shell with grouped sidebar"
```

## Task 3: Redesign Main Window as Tool Home

**Files:**
- Modify: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
- Modify: `ScreenshotTool/Features/Main/MainWindowView.swift`
- Modify: `ScreenshotToolTests/Features/MainWindowViewModelTests.swift`

- [ ] **Step 1: Write the failing main window quick actions test**

```swift
@MainActor
func testMainWindowReportsShortcutSummary() {
    let permissionsService = LocalFakePermissionsService()
    let router = WindowRouter()
    let historyStore = CaptureHistoryStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"), limit: 5)
    let viewModel = MainWindowViewModel(
        permissionsService: permissionsService,
        windowRouter: router,
        historyStore: historyStore
    )

    XCTAssertEqual(viewModel.shortcutSummary, "Command + Shift + 4")
}
```

- [ ] **Step 2: Run the main window tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/MainWindowViewModelTests`

Expected: FAIL with `Value of type 'MainWindowViewModel' has no member 'shortcutSummary'`

- [ ] **Step 3: Implement the minimal main-window data improvements**

```swift
var shortcutSummary: String {
    "Command + Shift + 4"
}
```

- [ ] **Step 4: Run the main window tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/MainWindowViewModelTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Features/Main ScreenshotToolTests/Features/MainWindowViewModelTests.swift
git commit -m "feat: redesign main window as tool home"
```

## Task 4: Improve Capture-Mode Contrast and Floating Toolbar Chrome

**Files:**
- Modify: `ScreenshotTool/Capture/Overlay/CaptureOverlayView.swift`
- Modify: `ScreenshotTool/Annotation/FloatingToolbar/FloatingToolbarController.swift`
- Test: `ScreenshotToolTests/Capture/CaptureOverlayContrastTests.swift`

- [ ] **Step 1: Write the failing contrast test**

```swift
import XCTest
@testable import ScreenshotTool

final class CaptureOverlayContrastTests: XCTestCase {
    func testContrastHelperChoosesLightBorderOnDarkBackground() {
        XCTAssertEqual(CaptureOverlayContrast.borderStyle(forBackgroundLuminance: 0.1), .light)
    }
}
```

- [ ] **Step 2: Run the contrast tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/CaptureOverlayContrastTests`

Expected: FAIL with `Cannot find 'CaptureOverlayContrast' in scope`

- [ ] **Step 3: Implement minimal contrast helper and apply it**

```swift
enum CaptureOverlayBorderStyle: Equatable {
    case light
    case dark
}

enum CaptureOverlayContrast {
    static func borderStyle(forBackgroundLuminance luminance: Double) -> CaptureOverlayBorderStyle {
        luminance < 0.5 ? .light : .dark
    }
}
```

- [ ] **Step 4: Run the contrast tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/CaptureOverlayContrastTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Capture/Overlay ScreenshotTool/Annotation/FloatingToolbar ScreenshotToolTests/Capture/CaptureOverlayContrastTests.swift
git commit -m "feat: improve capture mode contrast"
```

## Task 5: Refresh Settings Page Content Density

**Files:**
- Modify: `ScreenshotTool/Features/Settings/GeneralSettingsView.swift`
- Modify: `ScreenshotTool/Features/Settings/ScreenshotSettingsView.swift`
- Modify: `ScreenshotTool/Features/Settings/AnnotationSettingsView.swift`
- Modify: `ScreenshotTool/Features/Settings/InputMethodSettingsView.swift`
- Modify: `ScreenshotTool/Features/Settings/SettingsWindowViewModel.swift`
- Modify: `ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift`

- [ ] **Step 1: Write the failing settings-theme persistence test**

```swift
@MainActor
func testSetThemePreferencePersistsSelection() throws {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let preferencesStore = AppPreferencesStore(userDefaults: defaults)
    let rulesStore = InputMethodRulesStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json"))
    let viewModel = SettingsWindowViewModel(
        preferencesStore: preferencesStore,
        rulesStore: rulesStore,
        inputSourceService: FakeSettingsInputSourceService(),
        permissionsService: FakePermissionsService(),
        loginItemService: FakeLoginItemService(),
        inputMethodManager: InputMethodManager(
            preferencesStore: preferencesStore,
            rulesStore: rulesStore,
            inputSourceService: FakeSettingsInputSourceService(),
            matcher: InputMethodRuleMatcher()
        )
    )

    viewModel.setThemePreference(.dark)

    XCTAssertEqual(preferencesStore.appPreferences.themePreference, .dark)
}
```

- [ ] **Step 2: Run the settings view-model tests to verify they fail**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowViewModelTests`

Expected: FAIL with `Value of type 'SettingsWindowViewModel' has no member 'setThemePreference'`

- [ ] **Step 3: Implement the minimal settings content updates**

```swift
func setThemePreference(_ preference: AppThemePreference) {
    preferencesStore.updateApp { $0.themePreference = preference }
    appPreferences = preferencesStore.appPreferences
}
```

- [ ] **Step 4: Run the settings view-model tests to verify they pass**

Run: `make test-only TEST=ScreenshotToolTests/SettingsWindowViewModelTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Features/Settings ScreenshotToolTests/Features/SettingsWindowViewModelTests.swift
git commit -m "feat: refresh settings content density"
```

## Manual Verification Checklist

After completing the UI redesign implementation, run:

```bash
make test
./script/build_and_run.sh --verify
```

Expected:

- `make test` reports 0 failures
- `./script/build_and_run.sh --verify` exits successfully

Then manually verify:

1. Main window shows a clear hero area, primary `开始截图`, and a richer recent-captures area.
2. `打开设置` from the main window opens the settings window reliably.
3. Settings window uses left grouped sidebar navigation, not top tabs.
4. Theme selection offers `浅色 / 深色 / 跟随系统`.
5. Theme choice visibly affects both main and settings windows.
6. Screenshot mode overlay remains readable on both light and dark desktop content.
7. Floating toolbar remains legible against both bright and dark capture backgrounds.
8. Full editor shows a visible tool row and responds to rectangle, pen, and text interactions.
9. Input method settings still allow adding and removing rules after the visual redesign.

## Spec Coverage Notes

- Theme system is covered by Task 1 and Task 5.
- Sidebar-plus-card settings architecture is covered by Task 2 and Task 5.
- Tool-home main window is covered by Task 3.
- Capture-mode contrast is covered by Task 4.
- Annotation editor polish begins in Task 4 and continues through editor interaction verification.
- Permissions and diagnostics placement is covered in the shell and content-density tasks.
