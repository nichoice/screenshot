# ScreenshotTool

ScreenshotTool is a personal macOS screenshot utility for MacBook Air M4. It combines a `macshot`-style capture and annotation overlay with this app's own settings UI, output routing, menu bar behavior, hotkeys, and input source automation.

## Features

- macOS screenshot overlay based on imported `macshot` core code.
- Region selection, window snapping, and inline annotation toolbar.
- Screenshot output preferences for copy, save, or copy-and-save.
- Recent capture history in the main window.
- Global screenshot shortcut: `Command + Shift + 4`.
- App-wide theme setting: light, dark, or follow system.
- Optional menu bar icon while keeping background residency.
- Input source automation with a global default and per-app overrides.

## Project Structure

- `ScreenshotTool/`: main SwiftUI/AppKit macOS app.
- `MacShotCore/`: bridge framework and imported `macshot` screenshot core.
- `ScreenshotToolTests/`: app-level unit tests.
- `MacShotCoreTests/`: screenshot core unit tests.
- `project.yml`: XcodeGen project definition.
- `script/build_and_run.sh`: local build and run helper.

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

