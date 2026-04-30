# ScreenshotTool

ScreenshotTool is a personal macOS screenshot utility for MacBook Air M4. It combines a `macshot`-style capture and annotation overlay with this app's own settings UI, output routing, menu bar behavior, hotkeys, and input source automation.

## Features

- macOS screenshot overlay based on imported `macshot` core code.
- Region selection, window snapping, and inline annotation toolbar.
- Screenshot output preferences for clipboard-only, save-only, copy-and-save, or edit-first workflows.
- Configurable default save directory, defaulting to the Desktop.
- Global screenshot shortcut: `Command + Shift + 4`.
- App-wide theme setting: light, dark, or follow system.
- Optional menu bar icon while keeping background residency.
- Input source automation with a global default and per-app overrides.

## Output Boundary

- Clipboard-only screenshots are copied to the system clipboard only. ScreenshotTool does not write a saved image, preview cache image, or main-window history item for that action.
- Save-only and copy-and-save screenshots write image files to the configured default save directory. The default directory is the Desktop.
- Edit-first screenshots remain in the annotation overlay until the user explicitly chooses copy, save, share, or another toolbar action.

## Project Structure

- `ScreenshotTool/`: main SwiftUI/AppKit macOS app.
- `MacShotCore/`: bridge framework and imported `macshot` screenshot core.
- `ScreenshotToolTests/`: app-level unit tests.
- `MacShotCoreTests/`: screenshot core unit tests.
- `project.yml`: XcodeGen project definition.
- `script/build_and_run.sh`: local build and run helper.

## macshot Usage Scope

The screenshot engine is built around source imported from the local `macshot` project at `/Users/nic/Documents/workspace/screenshot/macshot`. Imported and modified files live under `MacShotCore/Imported`, with a small bridge layer in `MacShotCore/`.

The app currently uses these `macshot`-derived technologies:

| Area | `macshot` technology used in this project |
| --- | --- |
| Screen capture | ScreenCaptureKit-based full-screen and window capture, including multi-display capture and overlay-window exclusion. |
| Capture overlay | AppKit overlay windows, region selection, resize handles, border dragging, window snapping, and keyboard-driven capture actions. |
| Annotation canvas | `OverlayView`, annotation state, hit testing, undo/redo support, selection movement, resize/delete/edit behavior, and composited image export. |
| Annotation tools | Arrow, line, rectangle, filled rectangle, ellipse, pencil, marker, text, number, pixelate/blur, measure, loupe, stamp, and color sampling tool handlers. |
| Toolbar and popovers | Floating annotation toolbar, tool option rows, color/font/effects/emoji/gradient/list popovers, and toolbar feature gating. |
| Image utilities | Image encoding, image effects, beautify rendering, OCR helper, barcode detection, filename formatting, temporary share files, and language helper utilities where needed by the imported core. |
| Preferences bridge | `MacShotPreferencesAdapter` maps ScreenshotTool settings into the `UserDefaults` keys expected by the imported `macshot` core. |

The app intentionally does not use `macshot` as a whole application. ScreenshotTool keeps its own SwiftUI settings UI, main window, save-directory ownership, output routing, menu bar behavior, app theme settings, hotkey ownership, GitHub workflow, and input source automation. Some imported `macshot` features that are outside the current screenshot path are disabled or shimmed in `MacShotCore/Imported/MacShotFeatureShims.swift`.

## Requirements

- macOS 14 or later.
- Xcode with macOS SDK installed.
- XcodeGen for regenerating `ScreenshotTool.xcodeproj`.

Install XcodeGen if needed:

```bash
brew install xcodegen
```

## Build And Run

Generate the Xcode project:

```bash
make generate
```

Build and launch the app:

```bash
./script/build_and_run.sh
```

Build and verify that the process starts:

```bash
./script/build_and_run.sh --verify
```

Run tests:

```bash
make test
```

Run a single test target or test file path:

```bash
make test-only TEST=MacShotCoreTests/OverlayWindowControllerTests
```

## Local Deployment

For manual permission testing, copy the built app into `/Applications`:

```bash
pkill -x ScreenshotTool
rm -rf /Applications/ScreenshotTool.app
cp -R .build/xcode/Build/Products/Debug/ScreenshotTool.app /Applications/ScreenshotTool.app
codesign --force --deep --sign - /Applications/ScreenshotTool.app
open -n /Applications/ScreenshotTool.app
```

The command above uses ad-hoc signing. macOS privacy permissions are tied to the running app identity, and ad-hoc builds can change identity after rebuilds. If System Settings shows permissions enabled but the app still reports them as denied, remove and re-add the current `/Applications/ScreenshotTool.app` entry, then restart the app.

## Permissions

Screenshot capture needs Screen Recording permission:

`System Settings -> Privacy & Security -> Screen & System Audio Recording`

Input source automation and some window interactions need Accessibility permission:

`System Settings -> Privacy & Security -> Accessibility`

The app includes a diagnostics page that shows the current permission state and the running bundle path.

## License Notice

`MacShotCore` incorporates and modifies GPLv3-licensed source from the local `macshot` project. Keep `MacShotCore/LICENSE.macshot-GPLv3.txt` and `MacShotCore/NOTICE.md` with source or binary distributions.
