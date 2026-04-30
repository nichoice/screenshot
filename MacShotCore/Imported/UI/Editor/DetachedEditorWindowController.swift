import AppKit

private final class EditorWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.keyCode == 12 {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
final class DetachedEditorWindowController: NSObject, NSWindowDelegate {
    static var backgroundRemover: BackgroundRemoving = VisionBackgroundRemover()

    private var window: NSWindow?
    private var overlayView: OverlayView?
    private static var activeControllers: [DetachedEditorWindowController] = []

    static func open(
        image: NSImage,
        tool: AnnotationTool = .arrow,
        color: NSColor = .systemRed,
        strokeWidth: CGFloat = 3,
        annotations: [Annotation] = [],
        historyEntryID: String? = nil,
        fromCapture: Bool = false,
        disableBeautify: Bool = false
    ) {
        NSApp.setActivationPolicy(.regular)
        let controller = DetachedEditorWindowController()
        controller.show(
            image: image,
            tool: tool,
            color: color,
            strokeWidth: strokeWidth,
            annotations: annotations,
            disableBeautify: disableBeautify
        )
        activeControllers.append(controller)
    }

    private func show(
        image: NSImage,
        tool: AnnotationTool,
        color: NSColor,
        strokeWidth: CGFloat,
        annotations: [Annotation],
        disableBeautify: Bool
    ) {
        let imageSize = image.size
        let screenFrame = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let minimumWidth: CGFloat = 800
        let minimumHeight: CGFloat = 400
        let maximumWidth = screenFrame.width * 0.9
        let maximumHeight = screenFrame.height * 0.9
        let chromeWidth: CGFloat = 106
        let chromeHeight: CGFloat = 156
        let windowWidth = min(maximumWidth, max(minimumWidth, imageSize.width + chromeWidth))
        let windowHeight = min(maximumHeight, max(minimumHeight, imageSize.height + chromeHeight))

        let window = EditorWindow(
            contentRect: NSRect(
                x: screenFrame.midX - windowWidth / 2,
                y: screenFrame.midY - windowHeight / 2,
                width: windowWidth,
                height: windowHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screenshot Editor"
        window.minSize = NSSize(width: minimumWidth, height: minimumHeight)
        window.maxSize = NSSize(width: screenFrame.width, height: screenFrame.height)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.collectionBehavior = [.fullScreenAuxiliary]

        let editorView = EditorView()
        editorView.frame = NSRect(origin: .zero, size: imageSize)
        editorView.autoresizingMask = []
        editorView.screenshotImage = image
        editorView.overlayDelegate = self
        editorView.currentTool = tool
        editorView.currentColor = color
        editorView.currentStrokeWidth = strokeWidth
        if disableBeautify {
            editorView.beautifyEnabled = false
        }

        let topBarHeight: CGFloat = 32
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight - topBarHeight))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(white: 0.15, alpha: 1.0)
        scrollView.allowsMagnification = false
        scrollView.minMagnification = 0.1
        scrollView.maxMagnification = 8.0
        scrollView.horizontalScrollElasticity = .none
        scrollView.verticalScrollElasticity = .none
        scrollView.usesPredominantAxisScrolling = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 84, right: 50)
        scrollView.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: -84, right: -50)
        scrollView.contentView = CenteringClipView(frame: scrollView.contentView.frame)
        scrollView.documentView = editorView

        let container = NSView(frame: NSRect(origin: .zero, size: NSSize(width: windowWidth, height: windowHeight)))
        container.autoresizingMask = [.width, .height]
        container.addSubview(scrollView)

        let topBar = EditorTopBarView(frame: NSRect(x: 0, y: windowHeight - topBarHeight, width: windowWidth, height: topBarHeight))
        topBar.overlayView = editorView
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            topBar.updateSizeLabel(width: cgImage.width, height: cgImage.height)
        }
        container.addSubview(topBar)

        editorView.chromeParentView = container
        editorView.applySelection(NSRect(origin: .zero, size: imageSize))
        if !annotations.isEmpty {
            editorView.setAnnotations(annotations)
        }

        window.contentView = container
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(editorView)
        NSApp.activate(ignoringOtherApps: true)

        scrollView.documentView?.scroll(NSPoint(x: 0, y: editorView.frame.maxY))

        self.window = window
        self.overlayView = editorView
    }

    func windowWillClose(_ notification: Notification) {
        overlayView?.reset()
        overlayView?.overlayDelegate = nil
        window?.contentView = nil
        overlayView = nil
        window = nil
        Self.activeControllers.removeAll { $0 === self }
    }
}

extension DetachedEditorWindowController: OverlayViewDelegate {
    func overlayViewDidFinishSelection(_ rect: NSRect) {}
    func overlayViewSelectionDidChange(_ rect: NSRect) {}
    func overlayViewDidCancel() { window?.performClose(nil) }
    func overlayViewDidConfirm() {
        guard let image = overlayView?.captureSelectedRegion() else { return }
        ImageEncoder.copyToClipboard(image)
    }
    func overlayViewDidRequestSave() {
        guard let window, let image = overlayView?.captureSelectedRegion(), let imageData = ImageEncoder.encode(image) else { return }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [ImageEncoder.utType]
        savePanel.nameFieldStringValue = FilenameFormatter.defaultImageFilename()
        savePanel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = savePanel.url else { return }
            try? imageData.write(to: url)
        }
    }
    func overlayViewDidRequestPin() {}
    func overlayViewDidRequestOCR() {}
    func overlayViewDidRequestQuickSave() {
        overlayViewDidConfirm()
    }
    func overlayViewDidRequestFileSave() {
        overlayViewDidRequestSave()
    }
    func overlayViewDidRequestUpload() {}
    func overlayViewDidRequestShare(anchorView: NSView?) {}
    @available(macOS 14.0, *)
    func overlayViewDidRequestRemoveBackground() {
        guard let overlayView, let image = overlayView.captureSelectedRegionRaw() else { return }

        Task { @MainActor [weak self, weak overlayView] in
            do {
                let finalImage = try await Self.backgroundRemover.removeBackground(from: image)
                overlayView?.replaceScreenshotImageAfterBackgroundRemoval(finalImage)
            } catch {
                overlayView?.showOverlayError("Background removal failed — no clear subject found.")
                #if DEBUG
                    print("Vision background removal error: \(error.localizedDescription)")
                #endif
                _ = self
            }
        }
    }
    func overlayViewDidRequestEnterRecordingMode() {}
    func overlayViewDidRequestStartRecording(rect: NSRect) {}
    func overlayViewDidRequestStopRecording() {}
    func overlayViewDidRequestDetach() {}
    func overlayViewDidRequestScrollCapture(rect: NSRect) {}
    func overlayViewDidRequestStopScrollCapture() {}
    func overlayViewDidRequestToggleAutoScroll() {}
    func overlayViewDidRequestAccessibilityPermission() {}
    func overlayViewDidRequestInputMonitoringPermission() {}
    func overlayViewDidBeginSelection() {}
    func overlayViewRemoteSelectionDidChange(_ rect: NSRect) {}
    func overlayViewDidChangeWindowSnapState() {}
    func overlayViewRemoteSelectionDidFinish(_ rect: NSRect) {}
    func overlayViewDidRequestAddCapture() {}
}
