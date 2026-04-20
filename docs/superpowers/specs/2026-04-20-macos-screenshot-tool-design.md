# macOS Screenshot Tool Design

## Overview

This project is a self-use macOS screenshot utility for a MacBook Air M4. The primary goal is to deliver a screenshot experience similar to QQ Screenshot or WeChat Screenshot on macOS, with a polished native workflow for capture, annotation, copy, save, and pin-to-screen actions.

The app also includes a separate input method management feature in the settings area. This feature is not tied to the screenshot flow. It exists as a convenience feature inside the same app so the user does not need to build and run a separate utility.

The app is intended for local installation outside the App Store and may request macOS permissions such as Screen Recording, Accessibility, and related automation capabilities when needed.

## Goals

- Provide a native macOS screenshot workflow that feels close to QQ or WeChat screenshot tools.
- Support global hotkeys and background resident behavior.
- Support both a standard app window and an optional menu bar presence.
- Allow the app to keep running in the background even when the menu bar icon is disabled.
- Provide common annotation tools immediately after selecting a capture region.
- Support a floating annotation toolbar and a separate full editor window.
- Support pinning captured content to the screen.
- Keep a recent capture history.
- Provide a settings page with screenshot preferences and input method rules.
- Support a global default input method with per-application override rules.

## Non-Goals for v0.1

- OCR
- Scrolling capture or long screenshot stitching
- Cloud sync
- Multi-device preference sync
- Advanced pinned-window grouping or workspace management
- Replacing macOS system input source configuration at the system settings level

## Product Scope

### Application Shape

The app is a standard macOS application with these user-facing forms:

- A main window
- A settings window
- An optional menu bar icon and popover
- Background resident behavior

The app must support the following states:

- Running with main window open
- Running with main window closed but still resident in the background
- Running with menu bar icon enabled
- Running with menu bar icon disabled while global hotkeys and background features remain active

Fully quitting the app stops all background behavior, including screenshot hotkeys and input method switching.

### Screenshot Workflow

The default screenshot interaction is:

1. User presses a global hotkey.
2. The app enters a full-screen capture overlay mode.
3. User drags to create a selection region.
4. A floating toolbar appears near the selected region.
5. User can annotate, copy, save, pin to screen, or open the full editor window.

The app also supports entering a full editor window from the floating toolbar for more detailed editing.

### Input Method Workflow

The input method feature is independent of screenshot capture. It runs as a background rule engine that reacts to frontmost application changes.

Rule priority is:

1. Per-application input method rule
2. Global default input method

If a frontmost app has an explicit rule, that rule is applied. If it does not, the global default input method is applied. If the current input method already matches the desired target, the app does nothing.

The app should not aggressively fight manual user changes while staying in the same frontmost application. Rules are re-evaluated when the frontmost application changes.

## Technical Approach

### Recommended Approach

Use a hybrid native macOS architecture:

- AppKit for capture overlay, annotation canvas, global hotkeys, pin windows, and desktop-level window behavior
- SwiftUI for main window, settings UI, and app-level management flows

This approach provides the best balance of native behavior, performance, permission handling, and UI maintainability for a self-use macOS utility.

## Alternative Approaches Considered

### Mostly SwiftUI with minimal bridging

Pros:

- Faster to build simple forms and settings
- Cleaner declarative UI for app shell screens

Cons:

- Core screenshot behaviors still require AppKit-backed windows and system integration
- Floating toolbar and overlay behavior become awkward when forced into a mostly SwiftUI structure

### Cross-platform shell such as Tauri or Electron

Pros:

- Easier future portability if cross-platform becomes a hard requirement

Cons:

- Screenshot overlays, pinned windows, permissions, global hotkeys, and input method switching all rely on native bridges
- Heavier runtime
- Weaker fit for a native-feeling macOS utility

## Architecture

The app is split into five modules with clear responsibilities.

### 1. App Shell

Responsibilities:

- Manage app lifecycle
- Coordinate dock presence and app activation policy
- Control background resident behavior
- Manage menu bar icon visibility
- Open and close main and settings windows
- Display permission status and recovery actions

Likely implementation:

- `NSApplicationDelegate` for lifecycle hooks
- SwiftUI scenes or explicit window controllers for main and settings windows
- App-wide observable state for menu bar and residency status

### 2. Capture Engine

Responsibilities:

- Register and handle global screenshot hotkeys
- Enter and exit capture mode
- Manage capture overlay windows across displays
- Handle selection region logic
- Produce the captured image payload

Likely implementation:

- AppKit overlay windows per display
- Screen capture integration through native macOS APIs
- Shared capture session coordinator

### 3. Annotation Engine

Responsibilities:

- Manage annotation session state
- Render annotation tools and objects
- Provide floating toolbar actions
- Support full editor window flow
- Export final image
- Support pin-to-screen windows

Likely implementation:

- Annotation model objects separate from rendering layer
- AppKit-backed canvas for precise pointer interaction
- Shared session object so floating toolbar and editor window can act on the same underlying capture

### 4. Input Method Manager

Responsibilities:

- Observe frontmost application changes
- Resolve the desired input source from rules
- Apply global or per-app input source targets
- Track switch attempts and failures

Likely implementation:

- Frontmost app observer
- Input source abstraction around native macOS input source APIs
- Fail-safe behavior when target input source is unavailable

### 5. Settings and Persistence

Responsibilities:

- Persist preferences
- Persist input method rules
- Persist recent capture history metadata
- Expose change notifications to the running app

Likely implementation:

- `UserDefaults` for scalar preferences
- JSON files under `Application Support` for structured rules and history metadata
- Dedicated storage layer to avoid spreading persistence logic throughout UI code

## Window Model

The app uses six window or surface types.

### Main Window

Purpose:

- Show recent captures
- Provide quick actions
- Surface permission status
- Link into settings and common flows

### Settings Window

Purpose:

- Host all configurable preferences for screenshot, annotation, residency, and input method behavior

### Menu Bar Popover

Purpose:

- Provide quick access when menu bar icon is enabled
- Trigger screenshot, open settings, and inspect recent captures

### Capture Overlay Window

Purpose:

- Display full-screen dimmed overlay
- Handle selection rectangle and cursor guides
- Operate across one or more displays

### Floating Toolbar Window

Purpose:

- Appear near the current selection
- Offer immediate annotation and output actions

Behavior:

- Prefer placement below the selection
- Flip to another side when space is constrained

### Editor and Pin Windows

Editor window purpose:

- Allow deeper editing after initial capture

Pin window purpose:

- Display captured content as a lightweight always-on-top visual reference
- Support dragging and closing without stealing unnecessary focus

## Interaction Rules

These interaction rules should be treated as part of the product contract for v0.1.

- `Esc` cancels current capture or exits the active editing surface.
- Double-clicking a valid selection quickly finalizes the capture and copies it.
- `Command + C` copies the current result.
- `Command + S` saves the current result.
- Closing the main window does not quit the app if background residency is enabled.
- Hiding the menu bar icon does not disable background behavior.
- Quitting the app stops all resident behavior.

## Settings Structure

The settings window is split into four sections.

### General

- Launch at login
- Stay resident after closing windows
- Show or hide menu bar icon
- Keep a standard Dock-visible app shape for v0.1
- Permission status and recovery links

### Screenshot

- Global hotkey
- Default save directory
- Default output action
- Output format such as PNG or JPG
- Optional behavior flags such as cursor inclusion or sound cues

### Annotation

- Default color
- Default line width
- Default font size
- Remember last-used tool
- Pin window always-on-top preference
- Capture history retention limit

### Input Method

- Feature enabled toggle
- Global default input method
- Per-application override list
- Recent matching and failure status

## Data Model

The first version should use a lightweight persistence model with explicit types.

### Preferences

- `AppPreferences`
- `CapturePreferences`
- `AnnotationPreferences`
- `InputMethodPreferences`

### Rules and History

- `AppInputMethodRule`
- `CaptureHistoryItem`

## Suggested Storage Strategy

- `UserDefaults` for simple scalar preferences
- JSON files in `Application Support` for input method rules and recent capture metadata
- Dedicated app support subdirectory for cached capture thumbnails
- User-selected save directory for exported screenshots

This is intentionally simple for v0.1 and leaves room to migrate to `SwiftData` or SQLite later if needed.

## Input Method Rule Details

The input method manager should behave conservatively to avoid fighting the user.

### Rule Resolution

When the frontmost application changes:

1. Determine the app bundle identifier.
2. Check whether a per-app rule exists and is enabled.
3. If yes, use that rule's input source target.
4. Otherwise, use the global default input source target.
5. If there is no effective target, do nothing.
6. If the current input source already matches the target, do nothing.
7. Attempt the switch once and record success or failure.

### Manual Override Behavior

If the user manually changes the input method while staying inside the same app, the app does not immediately force it back. The configured rule is re-applied the next time the frontmost app changes and the current app becomes active again.

### Matching Strategy

Per-app rules should match by bundle identifier, not display name, because bundle identifiers are more stable and less ambiguous.

### Input Source Representation

Persist actual input source identifiers rather than generic labels such as "Chinese" or "English". The UI may display friendly names like `ABC`, `Sogou Pinyin`, or `Rime`, but rule storage must use stable system identifiers where possible.

### Failure Handling

If a switch fails:

- Record the failure event for diagnostics
- Surface a lightweight status in settings
- Do not enter a rapid retry loop

## Permissions and macOS Constraints

This app depends on macOS permissions and system behavior boundaries.

- Screenshot functionality requires Screen Recording permission.
- Some global event listening or low-level interaction may require Accessibility permission depending on implementation choices.
- Input source switching may rely on native input source APIs and accessibility-related behavior depending on the exact integration approach.
- The app should request and explain permissions clearly, but only when the relevant feature is used or enabled.

The app should not claim to replace system-level input source management. It is an app-level automation layer that reacts to frontmost app changes and applies preferred input sources.

## Testing Strategy

The project should separate deterministic logic from system-bound integration behavior.

### Automated Tests

Automated tests should cover:

- Input method rule resolution
- Preference read and write behavior
- Annotation model operations
- Capture history retention logic

These tests should target logic that can run without desktop permissions or live system APIs.

### Integration Abstractions

Wrap system-dependent functionality behind interfaces such as:

- `ScreenCaptureService`
- `HotkeyService`
- `InputSourceService`
- `PermissionsService`

This makes logic testable and keeps system integration swappable.

### Manual Verification

Manual verification is required for:

- Permission flows
- Multi-display overlay behavior
- Global hotkey behavior
- Floating toolbar placement
- Pin window interaction
- Real input method switching across target applications

## v0.1 Deliverables

The initial implementation should include:

- Global hotkey entry into screenshot mode
- Multi-display region capture
- Floating annotation toolbar
- Rectangle, arrow, text, freehand drawing, and blur or mosaic annotation tools
- Copy, save, open full editor, and pin-to-screen actions
- Main window
- Settings window
- Optional menu bar icon
- Background resident behavior
- Global default input method rule
- Per-application input method override rules
- Recent capture history

The app remains a standard Dock-visible macOS application in v0.1. Menu bar presence is optional, but Dock presence is not treated as a configurable feature in the first version.

## Open Implementation Risks

- Third-party input methods may behave inconsistently across applications.
- Some system APIs used for input source switching may be sensitive to macOS version differences.
- Window layering and focus behavior for overlays and pinned windows can be tricky on multi-display setups.
- Hiding Dock or menu bar presence while keeping correct resident behavior may require careful application activation policy handling.

These risks are acceptable for v0.1 as long as the architecture keeps system integrations isolated and testable.

## Recommended Next Step

After design approval, create a written implementation plan for v0.1 that:

- Chooses the app template and project layout
- Breaks the work into app shell, capture engine, annotation engine, input method manager, and persistence slices
- Defines initial test seams and interfaces before production code is written
