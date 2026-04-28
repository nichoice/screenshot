# macshot Core Integration Design

## Overview

The screenshot tool will replace its current custom SwiftUI/AppKit capture and inline annotation workflow with the mature capture core from the local `macshot` project at `/Users/nic/Documents/workspace/screenshot/macshot`.

The app shell remains ours:

- main window
- settings window
- theme preference
- background residency
- menu bar visibility
- global hotkey entry point
- input method automation
- output preferences

The screenshot core becomes `macshot`-based:

- multi-display capture overlay
- region selection
- window snapping
- screenshot-time toolbar
- annotation creation
- annotation selection, movement, resize, delete, and property editing
- text editing in-place
- final image generation

This direction was approved after confirming that `macshot` is GPLv3 licensed and the user selected direct source integration.

## Goals

- Use `macshot` as the primary screenshot and annotation engine.
- Keep the existing Screenshot Tool settings and input method functionality.
- Preserve the current app identity, bundle ID, menu bar behavior, and background resident behavior.
- Improve screenshot interaction quality by adopting `macshot`'s established AppKit overlay and annotation model.
- Route final screenshot output through the existing Screenshot Tool output layer, so copy/save/history preferences continue to work.
- Keep the first integration focused enough to build, test, and deploy quickly.

## Non-Goals

The first integration will not adopt every `macshot` feature.

Excluded from the first phase:

- screen recording
- GIF export
- scroll capture
- cloud upload
- Google Drive, imgbb, S3 uploaders
- Sparkle auto-update
- `macshot` settings window
- `macshot` menu bar menu
- `macshot` website and DMG resources
- full `macshot` screenshot history UI
- large localization import

These can be revisited after the basic capture and annotation path is stable.

## Licensing

`macshot` is licensed under GPLv3.

Because this plan directly incorporates `macshot` source code into this app, the combined project must be treated as GPLv3-compatible when distributed or pushed publicly. The repository should include:

- the GPLv3 license text from `macshot`
- attribution that identifies the imported source origin
- clear notices around modified files when practical

This is acceptable for the current self-use and public-source direction chosen by the user.

## Architecture

The app will use a shell-and-core structure.

### Screenshot Tool Shell

Existing code remains responsible for:

- app lifecycle through `ScreenshotToolApp`, `AppDelegate`, and `AppEnvironment`
- SwiftUI main/settings windows
- app theme handling
- menu bar icon visibility
- login item and background resident preferences
- global hotkey registration
- input method rules and frontmost app observation
- permission status display
- output preferences and recent capture history

### MacShotCore

New integrated source will live under:

`ScreenshotTool/MacShotCore`

This folder will contain the `macshot` pieces required for screenshot capture and annotation. Files will be imported in a scoped way instead of copying the entire app.

Expected groups:

- `Capture`
- `Overlay`
- `Toolbar`
- `Tools`
- `Model`
- `Services`
- `Windows`
- `Support`

### Bridge Layer

The bridge layer prevents the rest of Screenshot Tool from depending on `macshot` internals directly.

Planned bridge objects:

- `MacShotCaptureEngine`
- `MacShotCaptureSession`
- `MacShotPreferencesAdapter`
- `MacShotCaptureResult`

`AppEnvironment` will call `MacShotCaptureEngine.startCapture()` from the existing hotkey and menu actions.

The engine will call back into Screenshot Tool with:

- final annotated image
- optional raw image and annotations when available
- captured timestamp
- cancellation events
- permission or capture failures

## Data Flow

### Start Capture

1. User triggers screenshot from hotkey, main window, or menu bar.
2. `AppEnvironment` checks screen recording permission using the existing `PermissionsService`.
3. `MacShotPreferencesAdapter` syncs current Screenshot Tool preferences into the `macshot` core.
4. `MacShotCaptureEngine` starts a `MacShotCaptureSession`.
5. `macshot` overlay windows are shown on all active displays.
6. `macshot` captures the screen background while excluding its own overlay windows.

### Annotate

1. User selects a region or clicks a snapped window.
2. The `macshot` toolbar appears inside the overlay.
3. User edits with `macshot` tools.
4. Annotation object editing happens inside the `macshot` overlay:
   - click to select
   - drag to move
   - resize handles
   - delete selected annotation
   - edit text annotations
   - adjust stroke width, color, font size, and other tool-specific options

### Finish

1. User confirms the screenshot.
2. `macshot` produces the final composited `NSImage`.
3. The bridge converts the result into the existing Screenshot Tool output path.
4. `CaptureOutputService` applies current copy/save/history behavior.
5. The app refreshes recent capture state and returns focus appropriately.

### Cancel

1. User presses Escape or cancels from the toolbar.
2. `macshot` dismisses overlays.
3. The bridge tells `AppEnvironment` the capture was cancelled.
4. No output action runs.

## Preference Mapping

Screenshot Tool preferences remain the source of truth.

Initial mappings:

- `CapturePreferences.defaultOutputAction` controls copy/save behavior after `macshot` confirms.
- `CapturePreferences.defaultSaveDirectoryPath` controls where Screenshot Tool saves final output.
- `CapturePreferences.imageFormat` controls final export format through `CaptureOutputService`.
- `CapturePreferences.includeCursor` maps to `macshot` capture cursor defaults where supported.
- `CapturePreferences.playCaptureSound` remains handled by Screenshot Tool after successful capture.
- `AnnotationPreferences.defaultColorHex` maps to `macshot` current color.
- `AnnotationPreferences.defaultLineWidth` maps to `macshot` current stroke width.
- `AnnotationPreferences.defaultFontSize` maps to `macshot` text font size.
- `AnnotationPreferences.rememberLastTool` maps to `macshot` last tool behavior.

Any `macshot` preference that is not exposed in Screenshot Tool settings should use a sensible default in phase one.

## Build and Dependency Strategy

The first implementation should avoid importing `macshot` dependencies that are unrelated to screenshot capture.

Required or likely required Apple frameworks:

- AppKit
- CoreGraphics
- CoreImage
- ScreenCaptureKit
- Vision
- UniformTypeIdentifiers
- AVFoundation only if retained files require it for toolbar-adjacent behavior

Avoid in phase one:

- Sparkle
- Swift-WebP
- upload services
- video recording services

If a required `macshot` file imports a nonessential dependency, prefer extracting or trimming that specific dependency from the integrated core rather than pulling in the whole external package.

The Xcode project should include only the imported core files and the bridge files needed by the app target. Tests should not depend on live screen capture unless they are explicitly integration tests.

## Migration Phases

### Phase 1: Compile-Time Core Import

- Add `ScreenshotTool/MacShotCore`.
- Import the minimum required `macshot` model, overlay, toolbar, tool, and capture files.
- Rename or adapt conflicting symbols.
- Add GPLv3 attribution and license files.
- Build until the app target compiles.

### Phase 2: Bridge and Launch

- Add `MacShotCaptureEngine`.
- Wire existing screenshot actions to the new engine.
- Keep old `CaptureCoordinator` and SwiftUI inline editor available as a temporary fallback.
- Confirm that capture can start, cancel, and complete.

### Phase 3: Output Integration

- Route confirmed `macshot` images through `CaptureOutputService`.
- Preserve copy/save/history behavior.
- Preserve screenshot sound behavior.
- Refresh recent captures after completion.

### Phase 4: Preference Integration

- Implement `MacShotPreferencesAdapter`.
- Map Screenshot Tool settings to the imported core.
- Remove or neutralize `macshot` settings dependencies from the screenshot path.

### Phase 5: Cleanup

- Remove the old inline capture editor once the `macshot` path is stable.
- Remove now-unused old capture overlay tests or rewrite them for the bridge.
- Keep settings/input-method tests intact.
- Document remaining `macshot` features that are intentionally disabled.

## Error Handling

- If screen recording permission is missing, use existing Screenshot Tool permission handling and open the macOS settings page.
- If `macshot` capture returns no images, dismiss overlays and surface a non-blocking failure state.
- If output writing fails, keep the captured image in memory long enough for copy or retry when feasible.
- If a disabled `macshot` action is triggered from a toolbar item that remains visible, the bridge should ignore it or hide it in phase one.
- Cancel must always clear overlay windows and reset the capture-in-progress state.

## Testing Strategy

Unit tests should focus on the app-owned boundary:

- bridge starts and cancels sessions exactly once
- final `NSImage` results route to `CaptureOutputService`
- output preferences are preserved
- play-sound preference is honored
- `MacShotPreferencesAdapter` maps settings correctly
- permission-denied path does not start overlay

Manual verification is required for desktop behavior:

- region selection
- window snapping
- multi-display overlay placement
- Escape cancel
- toolbar placement above/below selection
- text annotation edit flow
- annotation select, move, resize, delete
- copy/save final output
- menu bar hidden but background resident behavior

## Risks

- `macshot` has a large `OverlayView`; importing only the necessary parts may expose hidden dependencies.
- Symbol names such as `Annotation`, `AnnotationTool`, and `PinWindowController` may conflict with existing Screenshot Tool types.
- `macshot` uses `UserDefaults` heavily, so settings ownership must be made explicit.
- GPLv3 obligations must be kept visible in the repository.
- Some `macshot` toolbar actions may need to be hidden until their backing services are imported or intentionally disabled.

## Acceptance Criteria

- Existing settings window still opens and controls Screenshot Tool preferences.
- Input method automation continues to work independently of screenshot capture.
- Screenshot hotkey launches the `macshot`-based overlay.
- Dragging a region immediately shows the `macshot` annotation toolbar.
- Clicking a window snaps to that window.
- Text, rectangle, arrow, and mosaic annotations can be created.
- Existing annotations can be selected, moved, resized, deleted, and edited where supported by `macshot`.
- Confirming a capture follows Screenshot Tool output preferences.
- Cancelling a capture leaves no stuck overlay or capture state.
- `make test` passes for app-owned tests.
- The app can be built and deployed to `/Applications/ScreenshotTool.app`.

