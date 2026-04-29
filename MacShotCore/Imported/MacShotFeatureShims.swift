import AppKit
import AVFoundation

/// Minimal compatibility shims for macshot features intentionally excluded from
/// the first screenshot-only import pass.
@MainActor
final class KeystrokeOverlay {
    static var hasInputMonitoringPermission: Bool { CGPreflightListenEventAccess() }
}

@MainActor
final class ScrollCaptureHUDPanel: NSPanel {
    let hudView = ScrollCaptureHUDView()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        contentView = hudView
    }

    func position(relativeTo selectionRect: NSRect, in overlayWindow: NSWindow) {
        setFrame(overlayWindow.convertToScreen(selectionRect), display: false)
    }
}

@MainActor
final class ScrollCaptureHUDView: NSView {
    var onStop: (() -> Void)?
    var onToggleAutoScroll: (() -> Void)?

    func update(
        stripCount: Int,
        pixelSize: CGSize,
        backingScale: CGFloat,
        maxScrollHeight: Int = 0,
        autoScrolling: Bool = false
    ) {}
}

enum WebcamPosition: String {
    case bottomRight
    case bottomLeft
    case topRight
    case topLeft
}

enum WebcamSize: String {
    case small
    case medium
    case large
}

enum WebcamShape: String {
    case circle
    case roundedRect
}

@MainActor
final class WebcamOverlay: NSPanel {
    static var availableCameras: [AVCaptureDevice] { [] }

    init(screen: NSScreen) {
        super.init(
            contentRect: NSRect(origin: screen.frame.origin, size: .zero),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
    }

    func configure(
        position: WebcamPosition,
        size: WebcamSize,
        shape: WebcamShape,
        recordingRect: NSRect
    ) {}

    func startPreview(deviceUID: String?) {}

    func stopPreview() {}

    func setDraggable(_ draggable: Bool) {
        ignoresMouseEvents = !draggable
    }
}

@MainActor
final class EditorTopBarView: NSView {
    weak var overlayView: OverlayView?
    var onDone: (() -> Void)?

    func updateSizeLabel(width: Int, height: Int) {}

    func updateZoom(_ magnification: CGFloat) {}

    func showDoneButton() {}
}

final class EditorView: OverlayView {
    var drewFromCompositeCache = false
}

enum DetachedEditorWindowController {
    static func open(
        image: NSImage,
        tool: AnnotationTool = .arrow,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3,
        annotations: [Annotation] = [],
        historyEntryID: String? = nil,
        fromCapture: Bool = false,
        disableBeautify: Bool = false
    ) {}
}

enum AppDelegate {
    static var captureSound: NSSound?
}

enum AutoRedactor {
    static let redactTypeNames: [(key: String, label: String)] = []

    static func redactPII(
        screenshot: NSImage,
        selectionRect: NSRect,
        captureDrawRect: NSRect,
        redactTool: AnnotationTool,
        color: NSColor,
        sourceImage: NSImage?,
        sourceImageBounds: NSRect,
        completion: @escaping ([Annotation]) -> Void
    ) {
        completion([])
    }

    static func redactAllText(
        screenshot: NSImage,
        selectionRect: NSRect,
        captureDrawRect: NSRect,
        redactTool: AnnotationTool,
        color: NSColor,
        sourceImage: NSImage?,
        sourceImageBounds: NSRect,
        completion: @escaping ([Annotation]) -> Void
    ) {
        completion([])
    }

    static func redactFaces(
        screenshot: NSImage,
        selectionRect: NSRect,
        captureDrawRect: NSRect,
        redactTool: AnnotationTool,
        color: NSColor,
        sourceImage: NSImage?,
        sourceImageBounds: NSRect,
        completion: @escaping ([Annotation]) -> Void
    ) {
        completion([])
    }

    static func redactPeople(
        screenshot: NSImage,
        selectionRect: NSRect,
        captureDrawRect: NSRect,
        redactTool: AnnotationTool,
        color: NSColor,
        sourceImage: NSImage?,
        sourceImageBounds: NSRect,
        completion: @escaping ([Annotation]) -> Void
    ) {
        completion([])
    }
}

enum TranslationProvider: String {
    case apple
    case google
}

enum TranslationService {
    static var provider: TranslationProvider = .google
    static var targetLanguage = "en"
    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("zh-CN", "Chinese (Simplified)")
    ]

    @available(macOS 15.0, *)
    static func checkAppleLanguageAvailability(completion: @escaping ([String: Bool]) -> Void) {
        completion(Dictionary(uniqueKeysWithValues: availableLanguages.map { ($0.code, true) }))
    }
}

enum TranslateOverlay {
    static func translate(
        screenshot: NSImage,
        selectionRect: NSRect,
        captureDrawRect: NSRect,
        targetLang: String,
        onError: @escaping (String) -> Void,
        completion: @escaping ([Annotation]) -> Void
    ) {
        completion([])
    }
}

enum SaveDirectoryAccess {
    static var displayPath: String {
        UserDefaults.standard.string(forKey: "saveDirectory") ?? "~/Pictures"
    }

    static func resolve() -> URL {
        if let path = UserDefaults.standard.string(forKey: "saveDirectory") {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    static func directoryHint() -> URL? {
        if let path = UserDefaults.standard.string(forKey: "saveDirectory") {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
    }

    static func save(url: URL) {
        UserDefaults.standard.set(url.path, forKey: "saveDirectory")
    }

    static func stopAccessing(url: URL) {}
}
