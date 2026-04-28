# macshot Core Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Screenshot Tool's custom screenshot overlay and inline annotation workflow with a GPLv3 `macshot`-based capture core while keeping Screenshot Tool's settings, input method automation, menu bar behavior, and output preferences.

**Architecture:** Add a separate `MacShotCore` framework target so imported `macshot` types stay outside the app module and do not collide with existing Screenshot Tool symbols. The app target talks to the core through a small bridge API, then routes confirmed images through the existing `CaptureOutputService`.

**Tech Stack:** Swift 5.10, AppKit, SwiftUI, CoreGraphics, ScreenCaptureKit, Vision, UniformTypeIdentifiers, XCTest, XcodeGen, GPLv3 source attribution

---

## Planned File Structure

- Modify: `project.yml`
  Add the `MacShotCore` framework target and make `ScreenshotTool` depend on it.
- Create: `MacShotCore/MacShotCaptureEngine.swift`
  Public bridge API used by the Screenshot Tool app.
- Create: `MacShotCore/MacShotCaptureSession.swift`
  Owns one active imported overlay session.
- Create: `MacShotCore/MacShotCaptureResult.swift`
  Value returned to the app after confirmation.
- Create: `MacShotCore/MacShotPreferences.swift`
  Public preferences value passed from Screenshot Tool into the core.
- Create: `MacShotCore/MacShotPreferencesAdapter.swift`
  Converts bridge preferences into `UserDefaults` keys expected by imported `macshot` code.
- Create: `MacShotCore/Support/MacShotCoreLicenseNotice.swift`
  Exposes source and GPLv3 attribution for diagnostics/about surfaces.
- Create: `MacShotCore/LICENSE.macshot-GPLv3.txt`
  Copy of `/Users/nic/Documents/workspace/screenshot/macshot/LICENSE`.
- Create: `MacShotCore/NOTICE.md`
  Human-readable attribution for the imported `macshot` source.
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
  Compose the new capture engine and route capture completion through output.
- Modify: `ScreenshotTool/App/CaptureHotkeyHandler.swift`
  Trigger the new capture entry point instead of `CaptureCoordinator`.
- Modify: `ScreenshotTool/App/MenuBarController.swift`
  Keep using the same start-capture closure, now backed by `MacShotCaptureEngine`.
- Modify: `ScreenshotTool/Features/Main/MainWindowViewModel.swift`
  Keep the existing start-capture closure, now backed by the new engine.
- Modify: `ScreenshotTool/Capture/CaptureOutputService.swift`
  Add a helper for already-rendered images so `macshot` output is not rendered again as an empty annotation document.
- Test: `MacShotCoreTests/MacShotPreferencesAdapterTests.swift`
  Verify Screenshot Tool preferences map to `macshot` defaults.
- Test: `MacShotCoreTests/MacShotCaptureSessionTests.swift`
  Verify start, cancel, and single-completion state behavior without live screen capture.
- Test: `ScreenshotToolTests/Smoke/AppEnvironmentTests.swift`
  Verify the app environment routes capture through the new start action.
- Test: `ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift`
  Verify already-rendered image output copies/saves/history correctly.

## Imported macshot Source Groups

When the bridge compiles, import source incrementally from `/Users/nic/Documents/workspace/screenshot/macshot/macshot`.

Start with these files and their immediate compile dependencies:

- `Model/Annotation.swift`
- `Model/AnnotationCodable.swift`
- `Capture/ScreenCaptureManager.swift`
- `UI/Overlay/OverlayWindowController.swift`
- `UI/Overlay/OverlayView.swift`
- `UI/Overlay/OverlayView+WindowSnapping.swift`
- `UI/Overlay/OverlayView+Popovers.swift`
- `UI/Overlay/ColorWheelRenderer.swift`
- `UI/Overlay/SelectionBorderOverlay.swift` only if required by compile-time references
- `UI/Toolbar/ToolbarDefinitions.swift`
- `UI/Toolbar/ToolbarStripView.swift`
- `UI/Toolbar/ToolbarButtonView.swift`
- `UI/Toolbar/ToolOptionsRowView.swift`
- `UI/Tools/AnnotationToolHandler.swift`
- `UI/Tools/ArrowToolHandler.swift`
- `UI/Tools/EllipseToolHandler.swift`
- `UI/Tools/FilledRectangleToolHandler.swift`
- `UI/Tools/LineToolHandler.swift`
- `UI/Tools/MarkerToolHandler.swift`
- `UI/Tools/NumberToolHandler.swift`
- `UI/Tools/PencilToolHandler.swift`
- `UI/Tools/PixelateToolHandler.swift`
- `UI/Tools/RectangleToolHandler.swift`
- `UI/Tools/StampToolHandler.swift`
- `UI/Tools/TextEditingController.swift`
- `UI/Tools/LoupeToolHandler.swift`
- `UI/Tools/MeasureToolHandler.swift`
- `UI/Popover/PopoverHelper.swift`
- `UI/Popover/ColorPickerView.swift`
- `UI/Popover/EmojiPickerView.swift`
- `UI/Popover/ListPickerView.swift`
- `UI/Popover/FontPickerView.swift`
- `Services/LanguageManager.swift`
- `Services/ImageEffects.swift`
- `Services/BeautifyRenderer.swift`
- `Services/ImageEncoder.swift`, trimmed if it requires `WebP`
- `Services/BarcodeDetector.swift`
- `Services/ToolShortcutManager.swift`
- `Services/TmpScratchDirectory.swift`
- `Services/FilenameFormatter.swift`
- `Services/VisionOCR.swift`

Do not import these in phase one:

- `AppDelegate.swift`
- `main.swift`
- `UI/Windows/SettingsWindowController.swift`
- upload services
- recording services
- Sparkle updater code
- website and packaging assets

## Task 1: Add the MacShotCore Module Shell

**Files:**
- Modify: `project.yml`
- Create: `MacShotCore/MacShotCaptureResult.swift`
- Create: `MacShotCore/MacShotPreferences.swift`
- Create: `MacShotCore/MacShotCaptureSession.swift`
- Create: `MacShotCore/MacShotCaptureEngine.swift`
- Create: `MacShotCoreTests/MacShotCaptureSessionTests.swift`

- [ ] **Step 1: Write the failing session tests**

Create `MacShotCoreTests/MacShotCaptureSessionTests.swift`:

```swift
import XCTest
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionTests: XCTestCase {
    func testSessionStartsOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults)

        XCTAssertTrue(session.start())
        XCTAssertFalse(session.start())
        XCTAssertEqual(session.state, .running)
    }

    func testCancelMovesSessionToCancelledOnce() {
        let session = MacShotCaptureSession(preferences: .defaults)
        _ = session.start()

        XCTAssertTrue(session.cancel())
        XCTAssertFalse(session.cancel())
        XCTAssertEqual(session.state, .cancelled)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make generate
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests
```

Expected: FAIL because `MacShotCoreTests` and `MacShotCaptureSession` do not exist.

- [ ] **Step 3: Add the framework and test targets**

Modify `project.yml` so it contains:

```yaml
name: ScreenshotTool
options:
  bundleIdPrefix: com.nic
settings:
  base:
    SWIFT_VERSION: 5.10
targets:
  MacShotCore:
    type: framework
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - MacShotCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.nic.MacShotCore
        PRODUCT_NAME: MacShotCore
        GENERATE_INFOPLIST_FILE: YES
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
    dependencies:
      - target: MacShotCore
  ScreenshotToolTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - ScreenshotToolTests
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - target: ScreenshotTool
  MacShotCoreTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - MacShotCoreTests
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - target: MacShotCore
```

- [ ] **Step 4: Add the minimal public bridge types**

Create `MacShotCore/MacShotCaptureResult.swift`:

```swift
import AppKit
import Foundation

public struct MacShotCaptureResult {
    public let image: NSImage
    public let capturedAt: Date

    public init(image: NSImage, capturedAt: Date) {
        self.image = image
        self.capturedAt = capturedAt
    }
}
```

Create `MacShotCore/MacShotPreferences.swift`:

```swift
import Foundation

public struct MacShotPreferences: Equatable {
    public var defaultColorHex: String
    public var defaultLineWidth: Double
    public var defaultFontSize: Double
    public var rememberLastTool: Bool
    public var includeCursor: Bool

    public init(
        defaultColorHex: String,
        defaultLineWidth: Double,
        defaultFontSize: Double,
        rememberLastTool: Bool,
        includeCursor: Bool
    ) {
        self.defaultColorHex = defaultColorHex
        self.defaultLineWidth = defaultLineWidth
        self.defaultFontSize = defaultFontSize
        self.rememberLastTool = rememberLastTool
        self.includeCursor = includeCursor
    }

    public static let defaults = MacShotPreferences(
        defaultColorHex: "#FF3B30",
        defaultLineWidth: 4,
        defaultFontSize: 16,
        rememberLastTool: true,
        includeCursor: false
    )
}
```

Create `MacShotCore/MacShotCaptureSession.swift`:

```swift
import Foundation

@MainActor
public final class MacShotCaptureSession {
    public enum State: Equatable {
        case idle
        case running
        case cancelled
        case completed
    }

    public private(set) var state: State = .idle
    public let preferences: MacShotPreferences

    public init(preferences: MacShotPreferences) {
        self.preferences = preferences
    }

    @discardableResult
    public func start() -> Bool {
        guard state == .idle else { return false }
        state = .running
        return true
    }

    @discardableResult
    public func cancel() -> Bool {
        guard state == .running else { return false }
        state = .cancelled
        return true
    }
}
```

Create `MacShotCore/MacShotCaptureEngine.swift`:

```swift
import Foundation

@MainActor
public final class MacShotCaptureEngine {
    private var activeSession: MacShotCaptureSession?

    public init() {}

    public var isCapturing: Bool {
        activeSession?.state == .running
    }

    @discardableResult
    public func startCapture(preferences: MacShotPreferences) -> Bool {
        guard activeSession?.state != .running else { return false }
        let session = MacShotCaptureSession(preferences: preferences)
        activeSession = session
        return session.start()
    }

    public func cancelCapture() {
        _ = activeSession?.cancel()
        activeSession = nil
    }
}
```

- [ ] **Step 5: Regenerate and run the new tests**

Run:

```bash
make generate
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add project.yml MacShotCore MacShotCoreTests
git commit -m "feat: add macshot core module shell"
```

## Task 2: Add GPLv3 Attribution and License Notice

**Files:**
- Create: `MacShotCore/LICENSE.macshot-GPLv3.txt`
- Create: `MacShotCore/NOTICE.md`
- Create: `MacShotCore/Support/MacShotCoreLicenseNotice.swift`
- Create: `MacShotCoreTests/MacShotCoreLicenseNoticeTests.swift`

- [ ] **Step 1: Write the failing license notice test**

Create `MacShotCoreTests/MacShotCoreLicenseNoticeTests.swift`:

```swift
import XCTest
@testable import MacShotCore

final class MacShotCoreLicenseNoticeTests: XCTestCase {
    func testNoticeNamesMacshotAndGPLv3() {
        XCTAssertTrue(MacShotCoreLicenseNotice.sourceProject.contains("macshot"))
        XCTAssertEqual(MacShotCoreLicenseNotice.license, "GPLv3")
        XCTAssertTrue(MacShotCoreLicenseNotice.sourcePath.contains("/macshot"))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCoreLicenseNoticeTests
```

Expected: FAIL with `Cannot find 'MacShotCoreLicenseNotice' in scope`.

- [ ] **Step 3: Add the notice type and attribution files**

Create `MacShotCore/Support/MacShotCoreLicenseNotice.swift`:

```swift
import Foundation

public enum MacShotCoreLicenseNotice {
    public static let sourceProject = "macshot"
    public static let license = "GPLv3"
    public static let sourcePath = "/Users/nic/Documents/workspace/screenshot/macshot"
}
```

Create `MacShotCore/NOTICE.md`:

```markdown
# MacShotCore Notice

This module incorporates and modifies source code from the local `macshot` project:

`/Users/nic/Documents/workspace/screenshot/macshot`

The imported source is licensed under GPLv3. Keep `LICENSE.macshot-GPLv3.txt` with this module when distributing source or binaries.
```

Create `MacShotCore/LICENSE.macshot-GPLv3.txt` by copying the exact text from:

`/Users/nic/Documents/workspace/screenshot/macshot/LICENSE`

Use:

```bash
cp /Users/nic/Documents/workspace/screenshot/macshot/LICENSE MacShotCore/LICENSE.macshot-GPLv3.txt
```

- [ ] **Step 4: Run the license tests**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCoreLicenseNoticeTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add MacShotCore/LICENSE.macshot-GPLv3.txt MacShotCore/NOTICE.md MacShotCore/Support/MacShotCoreLicenseNotice.swift MacShotCoreTests/MacShotCoreLicenseNoticeTests.swift
git commit -m "docs: add macshot gpl attribution"
```

## Task 3: Map Screenshot Tool Preferences Into MacShotCore

**Files:**
- Create: `MacShotCore/MacShotPreferencesAdapter.swift`
- Create: `MacShotCoreTests/MacShotPreferencesAdapterTests.swift`
- Modify: `ScreenshotTool/App/AppEnvironment.swift`

- [ ] **Step 1: Write the failing adapter tests**

Create `MacShotCoreTests/MacShotPreferencesAdapterTests.swift`:

```swift
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
                includeCursor: true
            )
        )

        XCTAssertEqual(defaults.string(forKey: "ScreenshotTool.defaultColorHex"), "#00AAFF")
        XCTAssertEqual(defaults.double(forKey: "currentStrokeWidth"), 7)
        XCTAssertEqual(defaults.double(forKey: "textFontSize"), 22)
        XCTAssertFalse(defaults.bool(forKey: "rememberLastTool"))
        XCTAssertTrue(defaults.bool(forKey: "captureCursor"))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotPreferencesAdapterTests
```

Expected: FAIL with `Cannot find 'MacShotPreferencesAdapter' in scope`.

- [ ] **Step 3: Implement the adapter**

Create `MacShotCore/MacShotPreferencesAdapter.swift`:

```swift
import Foundation

public final class MacShotPreferencesAdapter {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func apply(_ preferences: MacShotPreferences) {
        userDefaults.set(preferences.defaultColorHex, forKey: "ScreenshotTool.defaultColorHex")
        userDefaults.set(preferences.defaultLineWidth, forKey: "currentStrokeWidth")
        userDefaults.set(preferences.defaultFontSize, forKey: "textFontSize")
        userDefaults.set(preferences.rememberLastTool, forKey: "rememberLastTool")
        userDefaults.set(preferences.includeCursor, forKey: "captureCursor")
    }
}
```

- [ ] **Step 4: Add app-side preference conversion**

Modify `ScreenshotTool/App/AppEnvironment.swift` to import the framework:

```swift
import Foundation
import MacShotCore
```

Add this private helper near the bottom of `AppEnvironment`:

```swift
private extension AppEnvironment {
    var macShotPreferences: MacShotPreferences {
        MacShotPreferences(
            defaultColorHex: preferencesStore.annotationPreferences.defaultColorHex,
            defaultLineWidth: preferencesStore.annotationPreferences.defaultLineWidth,
            defaultFontSize: preferencesStore.annotationPreferences.defaultFontSize,
            rememberLastTool: preferencesStore.annotationPreferences.rememberLastTool,
            includeCursor: preferencesStore.capturePreferences.includeCursor
        )
    }
}
```

- [ ] **Step 5: Run adapter tests**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotPreferencesAdapterTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add MacShotCore/MacShotPreferencesAdapter.swift MacShotCoreTests/MacShotPreferencesAdapterTests.swift ScreenshotTool/App/AppEnvironment.swift
git commit -m "feat: map screenshot preferences to macshot core"
```

## Task 4: Add Already-Rendered Output Support

**Files:**
- Modify: `ScreenshotTool/Capture/CaptureOutputService.swift`
- Modify: `ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift`

- [ ] **Step 1: Write failing output tests**

Append these tests to `ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift`:

```swift
func testCopyRenderedImageWritesHistoryAndClipboard() throws {
    let clipboard = SpyClipboardService()
    let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-copy-history-\(UUID().uuidString).json")
    let cacheURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-copy-cache-\(UUID().uuidString)")
    let store = CaptureHistoryStore(fileURL: storeURL, limit: 20)
    let service = CaptureOutputService(
        renderer: AnnotationRenderer(),
        clipboardService: clipboard,
        historyStore: store,
        cacheDirectory: cacheURL
    )
    let image = Self.makeTestImage(width: 12, height: 10)

    let item = try service.copyRenderedImage(image, capturedAt: Date(timeIntervalSince1970: 123))

    XCTAssertEqual(clipboard.copiedImages.count, 1)
    XCTAssertTrue(item.didCopyToClipboard)
    XCTAssertEqual(store.items.count, 1)
}

func testSaveRenderedImageWritesFileAndHistory() throws {
    let clipboard = SpyClipboardService()
    let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-save-history-\(UUID().uuidString).json")
    let cacheURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-save-cache-\(UUID().uuidString)")
    let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("rendered-save-output-\(UUID().uuidString)")
    let store = CaptureHistoryStore(fileURL: storeURL, limit: 20)
    let service = CaptureOutputService(
        renderer: AnnotationRenderer(),
        clipboardService: clipboard,
        historyStore: store,
        cacheDirectory: cacheURL
    )
    let image = Self.makeTestImage(width: 12, height: 10)

    let item = try service.saveRenderedImage(
        image,
        capturedAt: Date(timeIntervalSince1970: 123),
        format: .png,
        directory: saveURL
    )

    XCTAssertNotNil(item.savedFilePath)
    XCTAssertTrue(FileManager.default.fileExists(atPath: item.savedFilePath ?? ""))
    XCTAssertEqual(store.items.count, 1)
}
```

If the test file does not already have helpers named `SpyClipboardService` and `makeTestImage`, add them as private test helpers:

```swift
private final class SpyClipboardService: ClipboardService {
    var copiedImages: [CGImage] = []
    var copiedTexts: [String] = []

    func copy(image: CGImage) {
        copiedImages.append(image)
    }

    func copy(text: String) {
        copiedTexts.append(text)
    }
}
```

```swift
private extension CaptureOutputServiceTests {
    static func makeTestImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
}
```

- [ ] **Step 2: Run the output tests to verify they fail**

Run:

```bash
make test-only TEST=ScreenshotToolTests/CaptureOutputServiceTests
```

Expected: FAIL because `copyRenderedImage` and `saveRenderedImage` do not exist.

- [ ] **Step 3: Implement rendered-image output methods**

Modify `ScreenshotTool/Capture/CaptureOutputService.swift` by adding these methods after `prepareShareItem`:

```swift
func copyRenderedImage(_ image: CGImage, capturedAt: Date) throws -> CaptureHistoryItem {
    clipboardService.copy(image: image)
    let previewURL = try writePreview(image)
    let item = CaptureHistoryItem(
        id: UUID(),
        createdAt: capturedAt,
        previewFilePath: previewURL.path,
        savedFilePath: nil,
        didCopyToClipboard: true
    )
    try historyStore.append(item)
    return item
}

func saveRenderedImage(
    _ image: CGImage,
    capturedAt: Date,
    format: CaptureImageFormat,
    directory: URL
) throws -> CaptureHistoryItem {
    let savedURL = try writeRenderedImage(image, format: format, directory: directory)
    let previewURL = try writePreview(image)
    let item = CaptureHistoryItem(
        id: UUID(),
        createdAt: capturedAt,
        previewFilePath: previewURL.path,
        savedFilePath: savedURL.path,
        didCopyToClipboard: false
    )
    try historyStore.append(item)
    return item
}
```

- [ ] **Step 4: Run output tests**

Run:

```bash
make test-only TEST=ScreenshotToolTests/CaptureOutputServiceTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/Capture/CaptureOutputService.swift ScreenshotToolTests/Capture/CaptureOutputServiceTests.swift
git commit -m "feat: support already-rendered capture output"
```

## Task 5: Wire AppEnvironment to the MacShotCore Shell

**Files:**
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Modify: `ScreenshotTool/App/CaptureHotkeyHandler.swift`
- Modify: `ScreenshotToolTests/Smoke/AppEnvironmentTests.swift`
- Create: `ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift`

- [ ] **Step 1: Write failing routing tests**

Create `ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift`:

```swift
import XCTest
@testable import ScreenshotTool

@MainActor
final class MacShotCaptureRoutingTests: XCTestCase {
    func testStartCaptureUsesMacShotCoreEngine() {
        let environment = AppEnvironment.bootstrapForTests()

        XCTAssertFalse(environment.macShotCaptureEngine.isCapturing)
        environment.startCapture()

        XCTAssertTrue(environment.macShotCaptureEngine.isCapturing)
    }
}
```

- [ ] **Step 2: Run the routing test to verify it fails**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotCaptureRoutingTests
```

Expected: FAIL because `macShotCaptureEngine` and `startCapture()` are not exposed.

- [ ] **Step 3: Add MacShotCore engine ownership to AppEnvironment**

Modify `ScreenshotTool/App/AppEnvironment.swift`:

```swift
import Foundation
import MacShotCore
```

Add a property near the existing services:

```swift
let macShotCaptureEngine: MacShotCaptureEngine
```

Add the initializer parameter:

```swift
macShotCaptureEngine: MacShotCaptureEngine,
```

Assign it:

```swift
self.macShotCaptureEngine = macShotCaptureEngine
```

Pass it from both bootstraps:

```swift
macShotCaptureEngine: MacShotCaptureEngine(),
```

Add this method to `AppEnvironment`:

```swift
func startCapture() {
    guard permissionsService.requestScreenRecordingAccessIfNeeded() else {
        permissionsService.openScreenRecordingSettings()
        return
    }

    _ = macShotCaptureEngine.startCapture(preferences: macShotPreferences)
}
```

Change `MainWindowViewModel` construction from:

```swift
startCaptureAction: {
    captureCoordinator.beginCapture()
}
```

to:

```swift
startCaptureAction: { [weak self] in
    self?.startCapture()
}
```

Because `self` is unavailable before initialization completes, perform this in two steps:

```swift
self.mainWindowViewModel = MainWindowViewModel(
    permissionsService: permissionsService,
    windowRouter: windowRouter,
    historyStore: historyStore,
    startCaptureAction: {}
)
```

Then add a public method to `MainWindowViewModel` in this same task only if needed:

```swift
func replaceStartCaptureAction(_ action: @escaping () -> Void) {
    startCaptureAction = action
}
```

If `startCaptureAction` is currently a `let`, change it to:

```swift
private var startCaptureAction: () -> Void
```

After `self` is initialized, set:

```swift
self.mainWindowViewModel.replaceStartCaptureAction { [weak self] in
    self?.startCapture()
}
```

- [ ] **Step 4: Update hotkey and menu bar wiring**

Modify `ScreenshotTool/App/CaptureHotkeyHandler.swift` so it accepts a closure instead of a `CaptureCoordinator`:

```swift
@MainActor
final class CaptureHotkeyHandler {
    private let hotkeyService: HotkeyService
    private let preferencesStore: AppPreferencesStore
    private let startCapture: () -> Void

    init(
        hotkeyService: HotkeyService,
        preferencesStore: AppPreferencesStore,
        startCapture: @escaping () -> Void
    ) {
        self.hotkeyService = hotkeyService
        self.preferencesStore = preferencesStore
        self.startCapture = startCapture
    }

    func start() throws {
        try hotkeyService.register(hotkey: preferencesStore.capturePreferences.hotkey) { [weak self] in
            Task { @MainActor in
                self?.startCapture()
            }
        }
    }

    func reload() throws {
        hotkeyService.unregisterAll()
        try start()
    }
}
```

In `AppEnvironment.bootstrap()` and `bootstrapForTests()`, construct the hotkey handler with a placeholder closure first:

```swift
let hotkeyHandler = CaptureHotkeyHandler(
    hotkeyService: CarbonHotkeyService(),
    preferencesStore: preferencesStore,
    startCapture: {}
)
```

If tests require replacing the closure after initialization, add:

```swift
func replaceStartCaptureAction(_ action: @escaping () -> Void) {
    startCapture = action
}
```

and change `private let startCapture` to `private var startCapture`.

Set the closure from `AppEnvironment.init` after properties are initialized:

```swift
hotkeyHandler.replaceStartCaptureAction { [weak self] in
    self?.startCapture()
}
```

Update `MenuBarController` construction so its `startCapture` closure calls `environment.startCapture()` through `AppEnvironment.init` wiring rather than `captureCoordinator.beginCapture()`.

- [ ] **Step 5: Run routing and hotkey tests**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotCaptureRoutingTests
make test-only TEST=ScreenshotToolTests/CaptureHotkeyHandlerTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ScreenshotTool/App/AppEnvironment.swift ScreenshotTool/App/CaptureHotkeyHandler.swift ScreenshotTool/Features/Main/MainWindowViewModel.swift ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift ScreenshotToolTests/Capture/CaptureHotkeyHandlerTests.swift
git commit -m "feat: route capture start through macshot core"
```

## Task 6: Import the Minimal macshot Overlay Core

**Files:**
- Create/modify: `MacShotCore/Imported/...`
- Modify: `MacShotCore/MacShotCaptureSession.swift`
- Modify: `MacShotCore/MacShotCaptureEngine.swift`
- Test: `MacShotCoreTests/MacShotCaptureSessionTests.swift`

- [ ] **Step 1: Add session delegate tests**

Append to `MacShotCoreTests/MacShotCaptureSessionTests.swift`:

```swift
func testSessionCompletesOnlyOnce() {
    let session = MacShotCaptureSession(preferences: .defaults)
    _ = session.start()
    let image = NSImage(size: NSSize(width: 10, height: 8))

    XCTAssertTrue(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 456)))
    XCTAssertFalse(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 789)))
    XCTAssertEqual(session.state, .completed)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests
```

Expected: FAIL because `complete(with:capturedAt:)` does not exist.

- [ ] **Step 3: Add completion state to the shell session**

Modify `MacShotCore/MacShotCaptureSession.swift`:

```swift
public private(set) var result: MacShotCaptureResult?

@discardableResult
public func complete(with image: NSImage, capturedAt: Date = Date()) -> Bool {
    guard state == .running else { return false }
    result = MacShotCaptureResult(image: image, capturedAt: capturedAt)
    state = .completed
    return true
}
```

Add `import AppKit` to the top of the file.

- [ ] **Step 4: Copy the minimal imported source groups**

Create:

```bash
mkdir -p MacShotCore/Imported/Model
mkdir -p MacShotCore/Imported/Capture
mkdir -p MacShotCore/Imported/UI/Overlay
mkdir -p MacShotCore/Imported/UI/Toolbar
mkdir -p MacShotCore/Imported/UI/Tools
mkdir -p MacShotCore/Imported/UI/Popover
mkdir -p MacShotCore/Imported/Services
```

Copy the first import batch:

```bash
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Model/Annotation.swift MacShotCore/Imported/Model/Annotation.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Model/AnnotationCodable.swift MacShotCore/Imported/Model/AnnotationCodable.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Capture/ScreenCaptureManager.swift MacShotCore/Imported/Capture/ScreenCaptureManager.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Overlay/OverlayWindowController.swift MacShotCore/Imported/UI/Overlay/OverlayWindowController.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Overlay/OverlayView.swift MacShotCore/Imported/UI/Overlay/OverlayView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Overlay/OverlayView+WindowSnapping.swift MacShotCore/Imported/UI/Overlay/OverlayView+WindowSnapping.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Overlay/OverlayView+Popovers.swift MacShotCore/Imported/UI/Overlay/OverlayView+Popovers.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Overlay/ColorWheelRenderer.swift MacShotCore/Imported/UI/Overlay/ColorWheelRenderer.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Toolbar/ToolbarDefinitions.swift MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Toolbar/ToolbarStripView.swift MacShotCore/Imported/UI/Toolbar/ToolbarStripView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Toolbar/ToolbarButtonView.swift MacShotCore/Imported/UI/Toolbar/ToolbarButtonView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Toolbar/ToolOptionsRowView.swift MacShotCore/Imported/UI/Toolbar/ToolOptionsRowView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/AnnotationToolHandler.swift MacShotCore/Imported/UI/Tools/AnnotationToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/ArrowToolHandler.swift MacShotCore/Imported/UI/Tools/ArrowToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/EllipseToolHandler.swift MacShotCore/Imported/UI/Tools/EllipseToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/FilledRectangleToolHandler.swift MacShotCore/Imported/UI/Tools/FilledRectangleToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/LineToolHandler.swift MacShotCore/Imported/UI/Tools/LineToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/MarkerToolHandler.swift MacShotCore/Imported/UI/Tools/MarkerToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/NumberToolHandler.swift MacShotCore/Imported/UI/Tools/NumberToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/PencilToolHandler.swift MacShotCore/Imported/UI/Tools/PencilToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/PixelateToolHandler.swift MacShotCore/Imported/UI/Tools/PixelateToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/RectangleToolHandler.swift MacShotCore/Imported/UI/Tools/RectangleToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/StampToolHandler.swift MacShotCore/Imported/UI/Tools/StampToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/TextEditingController.swift MacShotCore/Imported/UI/Tools/TextEditingController.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/LoupeToolHandler.swift MacShotCore/Imported/UI/Tools/LoupeToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Tools/MeasureToolHandler.swift MacShotCore/Imported/UI/Tools/MeasureToolHandler.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Popover/PopoverHelper.swift MacShotCore/Imported/UI/Popover/PopoverHelper.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Popover/ColorPickerView.swift MacShotCore/Imported/UI/Popover/ColorPickerView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Popover/EmojiPickerView.swift MacShotCore/Imported/UI/Popover/EmojiPickerView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Popover/ListPickerView.swift MacShotCore/Imported/UI/Popover/ListPickerView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/UI/Popover/FontPickerView.swift MacShotCore/Imported/UI/Popover/FontPickerView.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/LanguageManager.swift MacShotCore/Imported/Services/LanguageManager.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/ImageEffects.swift MacShotCore/Imported/Services/ImageEffects.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/BeautifyRenderer.swift MacShotCore/Imported/Services/BeautifyRenderer.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/BarcodeDetector.swift MacShotCore/Imported/Services/BarcodeDetector.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/ToolShortcutManager.swift MacShotCore/Imported/Services/ToolShortcutManager.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/TmpScratchDirectory.swift MacShotCore/Imported/Services/TmpScratchDirectory.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/FilenameFormatter.swift MacShotCore/Imported/Services/FilenameFormatter.swift
cp /Users/nic/Documents/workspace/screenshot/macshot/macshot/Services/VisionOCR.swift MacShotCore/Imported/Services/VisionOCR.swift
```

- [ ] **Step 5: Generate project and build to expose missing dependencies**

Run:

```bash
make generate
xcodebuild build -project ScreenshotTool.xcodeproj -scheme ScreenshotTool -destination 'platform=macOS'
```

Expected: The first run may fail with missing symbols from imported `macshot` files. Add only the missing directly referenced files or small shims needed for the screenshot path. Do not add Sparkle, upload services, recording engines, or full settings windows.

- [ ] **Step 6: Trim external dependency imports if needed**

If `ImageEncoder.swift` is required and imports `WebP`, replace WebP-specific branches with PNG/JPEG-only behavior inside the imported copy. Keep the public methods used by `OverlayWindowController`:

```swift
static func copyToClipboard(_ image: NSImage)
static func encode(_ image: NSImage) -> Data?
```

Expected: No `import WebP` remains in `MacShotCore`.

- [ ] **Step 7: Run module tests and build**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests
xcodebuild build -project ScreenshotTool.xcodeproj -scheme ScreenshotTool -destination 'platform=macOS'
```

Expected: PASS and BUILD SUCCEEDED.

- [ ] **Step 8: Commit**

```bash
git add MacShotCore project.yml MacShotCoreTests/MacShotCaptureSessionTests.swift
git commit -m "feat: import minimal macshot overlay core"
```

## Task 7: Connect MacShotCaptureSession to Imported Overlay Controllers

**Files:**
- Modify: `MacShotCore/MacShotCaptureSession.swift`
- Modify: `MacShotCore/MacShotCaptureEngine.swift`
- Create: `MacShotCore/MacShotImageConverter.swift`
- Test: `MacShotCoreTests/MacShotCaptureSessionTests.swift`

- [ ] **Step 1: Add an engine callback test**

Append to `MacShotCoreTests/MacShotCaptureSessionTests.swift`:

```swift
func testEngineStoresCompletionHandlerUntilSessionCompletes() {
    let engine = MacShotCaptureEngine()
    var received: MacShotCaptureResult?

    XCTAssertTrue(engine.startCapture(preferences: .defaults) { result in
        received = result
    } onCancel: {})

    let image = NSImage(size: NSSize(width: 10, height: 8))
    engine.completeForTesting(image: image, capturedAt: Date(timeIntervalSince1970: 321))

    XCTAssertEqual(received?.capturedAt, Date(timeIntervalSince1970: 321))
    XCTAssertFalse(engine.isCapturing)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests/testEngineStoresCompletionHandlerUntilSessionCompletes
```

Expected: FAIL because the callback overload and testing completion helper do not exist.

- [ ] **Step 3: Update engine callback API**

Modify `MacShotCore/MacShotCaptureEngine.swift`:

```swift
import AppKit
import Foundation

@MainActor
public final class MacShotCaptureEngine {
    private var activeSession: MacShotCaptureSession?
    private var onComplete: ((MacShotCaptureResult) -> Void)?
    private var onCancel: (() -> Void)?

    public init() {}

    public var isCapturing: Bool {
        activeSession?.state == .running
    }

    @discardableResult
    public func startCapture(
        preferences: MacShotPreferences,
        onComplete: @escaping (MacShotCaptureResult) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) -> Bool {
        guard activeSession?.state != .running else { return false }
        let session = MacShotCaptureSession(preferences: preferences)
        activeSession = session
        self.onComplete = onComplete
        self.onCancel = onCancel
        return session.start()
    }

    public func cancelCapture() {
        guard let session = activeSession else { return }
        _ = session.cancel()
        activeSession = nil
        onCancel?()
        onComplete = nil
        onCancel = nil
    }

    func completeForTesting(image: NSImage, capturedAt: Date) {
        guard let session = activeSession else { return }
        guard session.complete(with: image, capturedAt: capturedAt), let result = session.result else { return }
        activeSession = nil
        onComplete?(result)
        onComplete = nil
        onCancel = nil
    }
}
```

- [ ] **Step 4: Implement real overlay session ownership**

Modify `MacShotCore/MacShotCaptureSession.swift` so `start()` creates imported overlay controllers after applying preferences. Keep the existing state guard.

The first real implementation should follow this shape:

```swift
private var overlayControllers: [OverlayWindowController] = []

@discardableResult
public func start() -> Bool {
    guard state == .idle else { return false }
    MacShotPreferencesAdapter().apply(preferences)
    state = .running
    startImportedOverlayControllers()
    return true
}

private func startImportedOverlayControllers() {
    for screen in NSScreen.screens {
        let controller = OverlayWindowController(screen: screen)
        controller.overlayDelegate = self
        controller.showOverlay()
        overlayControllers.append(controller)
    }

    let excludedWindowNumbers = overlayControllers.map(\.windowNumber)
    ScreenCaptureManager.captureAllScreens(excludingWindowNumbers: excludedWindowNumbers) { [weak self] captures in
        guard let self else { return }
        if captures.isEmpty {
            _ = self.cancel()
            return
        }

        for capture in captures {
            self.overlayControllers.first(where: { $0.screen == capture.screen })?.setScreenshot(capture.image)
        }
    }
}
```

Then conform to `OverlayWindowControllerDelegate` in the same file. For unused phase-one actions, cancel or ignore explicitly:

```swift
extension MacShotCaptureSession: OverlayWindowControllerDelegate {
    func overlayDidCancel(_ controller: OverlayWindowController) {
        _ = cancel()
    }

    func overlayDidConfirm(_ controller: OverlayWindowController, capturedImage: NSImage?, annotationData: CaptureAnnotationData?) {
        guard let image = capturedImage else {
            _ = cancel()
            return
        }
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestPin(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestOCR(_ controller: OverlayWindowController, text: String, image: NSImage?) {
        if let image {
            _ = complete(with: image)
        } else {
            _ = cancel()
        }
        dismissOverlayControllers()
    }

    func overlayDidRequestUpload(_ controller: OverlayWindowController, image: NSImage) {
        _ = complete(with: image)
        dismissOverlayControllers()
    }

    func overlayDidRequestStartRecording(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {}
    func overlayDidRequestStopRecording(_ controller: OverlayWindowController) {}
    func overlayDidRequestScrollCapture(_ controller: OverlayWindowController, rect: NSRect, screen: NSScreen) {}
    func overlayDidRequestStopScrollCapture(_ controller: OverlayWindowController) {}
    func overlayDidRequestToggleAutoScroll(_ controller: OverlayWindowController) {}
    func overlayDidRequestAccessibilityPermission(_ controller: OverlayWindowController) {}
    func overlayDidRequestInputMonitoringPermission(_ controller: OverlayWindowController) {}
    func overlayDidBeginSelection(_ controller: OverlayWindowController) {}
    func overlayDidChangeSelection(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayDidRemoteResizeSelection(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayDidFinishRemoteResize(_ controller: OverlayWindowController, globalRect: NSRect) {}
    func overlayCrossScreenImage(_ controller: OverlayWindowController) -> NSImage? { nil }
    func overlayDidChangeWindowSnapState(_ controller: OverlayWindowController) {}
}
```

Add:

```swift
private func dismissOverlayControllers() {
    overlayControllers.forEach { $0.dismiss() }
    overlayControllers.removeAll()
}
```

Update `cancel()` to call `dismissOverlayControllers()`.

- [ ] **Step 5: Run tests and build**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotCaptureSessionTests
xcodebuild build -project ScreenshotTool.xcodeproj -scheme ScreenshotTool -destination 'platform=macOS'
```

Expected: PASS and BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add MacShotCore MacShotCoreTests/MacShotCaptureSessionTests.swift
git commit -m "feat: connect macshot overlay session"
```

## Task 8: Route Confirmed MacShot Images Through Screenshot Tool Output

**Files:**
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Modify: `MacShotCore/MacShotCaptureEngine.swift`
- Create: `ScreenshotToolTests/Smoke/MacShotOutputRoutingTests.swift`

- [ ] **Step 1: Write a focused output routing test**

Create `ScreenshotToolTests/Smoke/MacShotOutputRoutingTests.swift`:

```swift
import AppKit
import XCTest
@testable import ScreenshotTool

@MainActor
final class MacShotOutputRoutingTests: XCTestCase {
    func testMacShotCompletionRefreshesRecentCaptures() {
        let environment = AppEnvironment.bootstrapForTests()
        let image = Self.makeImage()

        environment.handleMacShotCaptureResultForTesting(image: image, capturedAt: Date(timeIntervalSince1970: 500))

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
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotOutputRoutingTests
```

Expected: FAIL because `handleMacShotCaptureResultForTesting` does not exist.

- [ ] **Step 3: Implement AppEnvironment result handling**

Modify `ScreenshotTool/App/AppEnvironment.swift`:

```swift
func handleMacShotCaptureResult(_ result: MacShotCaptureResult) {
    guard let cgImage = result.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

    let defaultDirectory = URL(
        fileURLWithPath: preferencesStore.capturePreferences.defaultSaveDirectoryPath
            ?? FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ScreenshotTool")
                .path
    )

    switch preferencesStore.capturePreferences.defaultOutputAction {
    case .copyOnly:
        _ = try? outputService.copyRenderedImage(cgImage, capturedAt: result.capturedAt)
    case .saveOnly:
        _ = try? outputService.saveRenderedImage(
            cgImage,
            capturedAt: result.capturedAt,
            format: preferencesStore.capturePreferences.imageFormat,
            directory: defaultDirectory
        )
    case .copyAndSave:
        _ = try? outputService.saveRenderedImage(
            cgImage,
            capturedAt: result.capturedAt,
            format: preferencesStore.capturePreferences.imageFormat,
            directory: defaultDirectory
        )
        _ = try? outputService.copyRenderedImage(cgImage, capturedAt: result.capturedAt)
    case .openEditor:
        let captureResult = CaptureResult(
            fullImage: cgImage,
            image: cgImage,
            selectionRect: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)),
            capturedAt: result.capturedAt
        )
        windowRouter.presentFloatingToolbar(
            for: captureResult,
            document: AnnotationDocument(),
            outputService: outputService,
            ocrService: ocrService,
            shareService: shareService,
            defaultSaveDirectory: defaultDirectory,
            imageFormat: preferencesStore.capturePreferences.imageFormat,
            defaultOutputAction: .openEditor
        )
    }

    if preferencesStore.capturePreferences.playCaptureSound {
        captureSoundPlayer.playCaptureSound()
    }
    mainWindowViewModel.refresh()
}
```

Add a test-only helper:

```swift
#if DEBUG
func handleMacShotCaptureResultForTesting(image: NSImage, capturedAt: Date) {
    handleMacShotCaptureResult(MacShotCaptureResult(image: image, capturedAt: capturedAt))
}
#endif
```

Update `startCapture()` so the engine callback uses the handler:

```swift
_ = macShotCaptureEngine.startCapture(
    preferences: macShotPreferences,
    onComplete: { [weak self] result in
        self?.handleMacShotCaptureResult(result)
    },
    onCancel: {}
)
```

- [ ] **Step 4: Run routing tests**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotOutputRoutingTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/App/AppEnvironment.swift ScreenshotToolTests/Smoke/MacShotOutputRoutingTests.swift
git commit -m "feat: route macshot output through app preferences"
```

## Task 9: Disable or Hide Unsupported macshot Toolbar Actions

**Files:**
- Modify: `MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift`
- Modify: `MacShotCore/Imported/UI/Overlay/OverlayView.swift`
- Test: `MacShotCoreTests/MacShotToolbarPolicyTests.swift`

- [ ] **Step 1: Write the toolbar policy test**

Create `MacShotCoreTests/MacShotToolbarPolicyTests.swift`:

```swift
import XCTest
@testable import MacShotCore

final class MacShotToolbarPolicyTests: XCTestCase {
    func testPhaseOneBottomToolbarDoesNotExposeUnsupportedActions() {
        let actions = ToolbarLayout.bottomButtons(
            selectedTool: .arrow,
            selectedColor: .systemRed,
            hasAnnotations: false
        ).map(\.action)

        XCTAssertFalse(actions.contains(.record))
        XCTAssertFalse(actions.contains(.scrollCapture))
        XCTAssertFalse(actions.contains(.upload))
        XCTAssertFalse(actions.contains(.effects))
        XCTAssertFalse(actions.contains(.beautify))
    }
}
```

- [ ] **Step 2: Run the test to verify current behavior**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotToolbarPolicyTests
```

Expected: It may fail if imported toolbar exposes unsupported actions.

- [ ] **Step 3: Gate unsupported actions**

In `MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift`, add:

```swift
enum MacShotCoreFeatureFlags {
    static let recordingEnabled = false
    static let scrollCaptureEnabled = false
    static let uploadEnabled = false
    static let beautifyEnabled = false
    static let effectsEnabled = false
}
```

Wrap unsupported buttons so they are not appended when the flag is false. For example:

```swift
if MacShotCoreFeatureFlags.effectsEnabled && !isRecording && actionEnabled(1013) {
    var effectsBtn = ToolbarButton(
        action: .effects,
        sfSymbol: "slider.horizontal.3",
        tooltip: L("Adjust")
    )
    if effectsActive {
        effectsBtn.tintColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
    }
    buttons.append(effectsBtn)
}
```

Apply the same pattern to recording, scroll capture, upload, and beautify buttons.

- [ ] **Step 4: Run toolbar tests**

Run:

```bash
make test-only TEST=MacShotCoreTests/MacShotToolbarPolicyTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add MacShotCore/Imported/UI/Toolbar/ToolbarDefinitions.swift MacShotCoreTests/MacShotToolbarPolicyTests.swift
git commit -m "feat: hide unsupported macshot actions"
```

## Task 10: Remove Old Capture Overlay Entry From Runtime Path

**Files:**
- Modify: `ScreenshotTool/App/AppEnvironment.swift`
- Modify: `ScreenshotTool/App/WindowRouter.swift`
- Keep but stop using: `ScreenshotTool/Capture/CaptureCoordinator.swift`
- Keep but stop using: `ScreenshotTool/Capture/Overlay/CaptureOverlayView.swift`
- Keep but stop using: `ScreenshotTool/Annotation/Inline/InlineAnnotationEditorView.swift`
- Test: `ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift`

- [ ] **Step 1: Add a regression test for no old overlay path on start**

Append to `ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift`:

```swift
func testStartCaptureDoesNotMarkOldCoordinatorCapturing() {
    let environment = AppEnvironment.bootstrapForTests()

    environment.startCapture()

    XCTAssertFalse(environment.captureCoordinator.isCapturing)
    XCTAssertTrue(environment.macShotCaptureEngine.isCapturing)
}
```

- [ ] **Step 2: Run the regression test**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotCaptureRoutingTests
```

Expected: PASS once app start is fully routed through `MacShotCaptureEngine`.

- [ ] **Step 3: Remove old overlay presentation from AppEnvironment start path**

In `ScreenshotTool/App/AppEnvironment.swift`, remove or leave unused the old `captureCoordinator.onCaptureStarted` overlay presentation block:

```swift
captureCoordinator.onCaptureStarted = { ... windowRouter?.showCaptureOverlay(...) ... }
```

Do not delete old types in this task. Keeping them for one stabilization cycle makes rollback easier.

- [ ] **Step 4: Run smoke tests**

Run:

```bash
make test-only TEST=ScreenshotToolTests/MacShotCaptureRoutingTests
make test-only TEST=ScreenshotToolTests/ScreenshotToolSmokeTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ScreenshotTool/App/AppEnvironment.swift ScreenshotToolTests/Smoke/MacShotCaptureRoutingTests.swift
git commit -m "refactor: remove old overlay from capture start path"
```

## Task 11: Full Verification and Local Deployment

**Files:**
- No source edits expected unless verification finds a real issue.

- [ ] **Step 1: Run full tests**

Run:

```bash
make test
```

Expected: all unit tests pass.

- [ ] **Step 2: Build debug app**

Run:

```bash
xcodebuild -project ScreenshotTool.xcodeproj -scheme ScreenshotTool -configuration Debug -derivedDataPath .build/xcode build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Deploy to Applications**

Run:

```bash
pkill -x ScreenshotTool
rm -rf /Applications/ScreenshotTool.app
cp -R .build/xcode/Build/Products/Debug/ScreenshotTool.app /Applications/ScreenshotTool.app
codesign --force --deep --sign - /Applications/ScreenshotTool.app
open -n /Applications/ScreenshotTool.app
```

Expected: app opens from `/Applications/ScreenshotTool.app`.

- [ ] **Step 4: Manual screenshot smoke test**

Verify manually:

- hotkey opens `macshot`-style overlay
- drag region shows toolbar immediately
- click window snaps selection
- rectangle annotation can be drawn
- arrow annotation can be drawn
- text annotation can be created and edited
- selected annotation can be moved
- selected annotation can be deleted
- confirm copies/saves according to Screenshot Tool settings
- Escape cancels and leaves no overlay

- [ ] **Step 5: Handle verification fixes**

If verification finds a defect, stop this verification task and write a focused follow-up task that names the exact failing behavior, exact files to change, and exact tests to run. Do not create a catch-all commit from this step.

If no fixes were needed, do not create an empty commit.
