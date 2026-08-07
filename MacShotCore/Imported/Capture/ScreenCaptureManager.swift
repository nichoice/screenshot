import Cocoa
import ScreenCaptureKit

struct ScreenCapture {
    let screen: NSScreen
    let image: CGImage
}

@MainActor
final class ShareableContentCache<Value> {
    typealias Loader = @MainActor () async throws -> Value

    private let loader: Loader
    private var cachedValue: Value?
    private var loadTask: Task<Value, Error>?

    init(loader: @escaping Loader) {
        self.loader = loader
    }

    func value() async throws -> Value {
        if let cachedValue {
            return cachedValue
        }
        if let loadTask {
            return try await loadTask.value
        }

        let loader = self.loader
        let task = Task { try await loader() }
        loadTask = task

        do {
            let value = try await task.value
            cachedValue = value
            loadTask = nil
            return value
        } catch {
            loadTask = nil
            throw error
        }
    }

    func invalidate() {
        cachedValue = nil
        loadTask?.cancel()
        loadTask = nil
    }

    func replace(with value: Value) {
        loadTask?.cancel()
        loadTask = nil
        cachedValue = value
    }
}

enum ScreenCaptureExclusionStrategy: Equatable {
    case currentApplication
    case cachedWindows
    case freshWindows

    static func resolve(
        currentApplicationAvailable: Bool,
        excludedWindowCount: Int
    ) -> ScreenCaptureExclusionStrategy {
        if currentApplicationAvailable {
            return .currentApplication
        }
        return excludedWindowCount > 0 ? .freshWindows : .cachedWindows
    }
}

@MainActor
class ScreenCaptureManager {

    // MARK: - SCShareableContent cache

    private static let contentCache = ShareableContentCache<SCShareableContent> {
        try await loadShareableContent()
    }
    private static var screenChangeObserver: NSObjectProtocol?

    private static func shareableContent() async throws -> SCShareableContent {
        installScreenChangeObserverIfNeeded()
        return try await contentCache.value()
    }

    static func prewarm() {
        installScreenChangeObserverIfNeeded()
        Task {
            _ = try? await shareableContent()
        }
    }

    private static func loadShareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )
    }

    private static func installScreenChangeObserverIfNeeded() {
        guard screenChangeObserver == nil else { return }
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                contentCache.invalidate()
                _ = try? await contentCache.value()
            }
        }
    }

    static func captureAllScreens(
        excludingWindowNumbers: [CGWindowID] = [], completion: @escaping ([ScreenCapture]) -> Void
    ) {
        Task {
            do {
                var content = try await shareableContent()
                let currentProcessID = ProcessInfo.processInfo.processIdentifier
                var currentApplication = content.applications.first {
                    $0.processID == currentProcessID
                }
                let exclusionStrategy = ScreenCaptureExclusionStrategy.resolve(
                    currentApplicationAvailable: currentApplication != nil,
                    excludedWindowCount: excludingWindowNumbers.count
                )

                // Current-app exclusion covers every overlay and app window while keeping
                // the cached display snapshot reusable. Window exclusion is only a fallback.
                if exclusionStrategy == .freshWindows {
                    content = try await loadShareableContent()
                    contentCache.replace(with: content)
                    currentApplication = content.applications.first {
                        $0.processID == currentProcessID
                    }
                }
                let displays = content.displays
                let screens = NSScreen.screens

                // Resolve window numbers to SCWindow objects for exclusion
                let excludedSCWindows: [SCWindow] = excludingWindowNumbers.compactMap { wid in
                    content.windows.first(where: { CGWindowID($0.windowID) == wid })
                }

                // Build display-screen pairs
                var pairs: [(SCDisplay, NSScreen)] = []
                for display in displays {
                    if let screen = screens.first(where: { nsScreen in
                        let screenNumber =
                            nsScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                            as? CGDirectDisplayID
                        return screenNumber == display.displayID
                    }) {
                        pairs.append((display, screen))
                    }
                }

                // Capture all displays concurrently
                let captures = await withTaskGroup(
                    of: ScreenCapture?.self, returning: [ScreenCapture].self
                ) { group in
                    for (display, screen) in pairs {
                        group.addTask {
                            // SnapPii targets macOS 14+, so keep the imported core on
                            // ScreenCaptureKit and avoid removed CoreGraphics capture APIs.
                            let filter: SCContentFilter
                            if let currentApplication {
                                filter = SCContentFilter(
                                    display: display,
                                    excludingApplications: [currentApplication],
                                    exceptingWindows: []
                                )
                            } else {
                                filter = SCContentFilter(
                                    display: display,
                                    excludingWindows: excludedSCWindows
                                )
                            }
                            let config = SCStreamConfiguration()
                            let scale = Int(screen.backingScaleFactor)
                            config.width = display.width * scale
                            config.height = display.height * scale
                            config.showsCursor = UserDefaults.standard.bool(
                                forKey: "captureCursor")
                            config.captureResolution = .best

                            guard
                                let image = try? await SCScreenshotManager.captureImage(
                                    contentFilter: filter, configuration: config
                                )
                            else { return nil }
                            return ScreenCapture(screen: screen, image: image)
                        }
                    }
                    var results: [ScreenCapture] = []
                    for await capture in group {
                        if let capture = capture {
                            results.append(capture)
                        }
                    }
                    return results
                }

                await MainActor.run { completion(captures) }
            } catch {
                #if DEBUG
                    NSLog("macshot: screen capture error: \(error.localizedDescription)")
                #endif
                await MainActor.run { completion([]) }
            }
        }
    }

    /// Captures only the requested display. The overlay can be shown before this
    /// finishes, so the first interaction is not blocked by a multi-display capture.
    static func captureScreen(
        _ screen: NSScreen,
        excludingWindowNumbers: [CGWindowID] = []
    ) async -> CGImage? {
        guard let content = try? await shareableContent() else { return nil }
        let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        guard let display = content.displays.first(where: { $0.displayID == screenID }) else {
            return nil
        }

        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let currentApplication = content.applications.first { $0.processID == currentProcessID }
        let excludedSCWindows = excludingWindowNumbers.compactMap { windowID in
            content.windows.first(where: { CGWindowID($0.windowID) == windowID })
        }
        let filter: SCContentFilter
        if let currentApplication {
            filter = SCContentFilter(
                display: display,
                excludingApplications: [currentApplication],
                exceptingWindows: []
            )
        } else {
            filter = SCContentFilter(display: display, excludingWindows: excludedSCWindows)
        }

        let config = SCStreamConfiguration()
        let scale = Int(screen.backingScaleFactor)
        config.width = display.width * scale
        config.height = display.height * scale
        config.showsCursor = UserDefaults.standard.bool(forKey: "captureCursor")
        config.captureResolution = .best

        return try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    // MARK: - Single window capture (with transparency)

    /// Captures a single window by its CGWindowID, returning an image with transparent corners.
    /// Uses `desktopIndependentWindow` filter for clean transparent background where available.
    static func captureWindow(windowID: CGWindowID, screen: NSScreen) async -> CGImage? {
        guard
            let content = try? await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
        else { return nil }
        guard
            let scWindow = content.windows.first(where: { CGWindowID($0.windowID) == windowID })
        else { return nil }

        let filter: SCContentFilter
        if #available(macOS 14.2, *) {
            filter = SCContentFilter(desktopIndependentWindow: scWindow)
        } else {
            guard
                let display = content.displays.first(where: {
                    let screenID =
                        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                        as? CGDirectDisplayID
                    return screenID != nil && $0.displayID == screenID!
                }) ?? content.displays.first
            else { return nil }
            let otherWindows = content.windows.filter { CGWindowID($0.windowID) != windowID }
            filter = SCContentFilter(display: display, excludingWindows: otherWindows)
        }

        let config = SCStreamConfiguration()
        let scale = Int(screen.backingScaleFactor)
        config.width = Int(scWindow.frame.width) * scale
        config.height = Int(scWindow.frame.height) * scale
        config.showsCursor = false
        config.captureResolution = .best

        guard
            let image = try? await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
        else { return nil }
        return image
    }
}
