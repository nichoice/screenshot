import AppKit
import Foundation
import SwiftUI

@MainActor
protocol ShareService {
    func share(fileURL: URL)
}

@MainActor
final class SystemShareService: ShareService {
    func share(fileURL: URL) {
        let picker = NSSharingServicePicker(items: [fileURL])
        guard let view = NSApp.keyWindow?.contentView else { return }
        let rect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        picker.show(relativeTo: rect, of: view, preferredEdge: .minY)
    }
}

@MainActor
final class WindowRouter: ObservableObject {
    private var overlayWindows: [CaptureOverlayWindow] = []
    private var captureCancelEventMonitor: Any?
    private var globalCaptureCancelEventMonitor: Any?
    private let floatingToolbarController = FloatingToolbarController()
    private let editorWindowController = EditorWindowController()
    private let pinWindowController = PinWindowController()
    private var openSettingsHandler: (() -> Void)?

    func configureOpenSettings(_ handler: @escaping () -> Void) {
        openSettingsHandler = handler
    }

    func openSettings() {
        if let openSettingsHandler {
            openSettingsHandler()
            return
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func showCaptureOverlay(
        onSelectionChanged: @escaping (CGPoint, CGPoint) -> Void,
        onSelectionCompleted: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) {
        hideCaptureOverlay()
        NSApp.activate(ignoringOtherApps: true)
        captureCancelEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                onCancelled()
                return nil
            }

            return event
        }
        globalCaptureCancelEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 53 else { return }
            Task { @MainActor in
                onCancelled()
            }
        }
        overlayWindows = NSScreen.screens.map { screen in
            let view = CaptureOverlayView(
                frame: CGRect(origin: .zero, size: screen.frame.size),
                screenFrame: screen.frame
            )
            view.onSelectionChanged = { start, end in
                onSelectionChanged(
                    CaptureCoordinateConverter.localPointToGlobal(start, screenFrame: screen.frame),
                    CaptureCoordinateConverter.localPointToGlobal(end, screenFrame: screen.frame)
                )
            }
            view.onSelectionCompleted = onSelectionCompleted
            view.onCancelled = onCancelled
            let window = CaptureOverlayWindow(contentView: view, frame: screen.frame)
            window.onCancelled = onCancelled
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            window.makeKey()
            return window
        }
    }

    func hideCaptureOverlay() {
        if let captureCancelEventMonitor {
            NSEvent.removeMonitor(captureCancelEventMonitor)
            self.captureCancelEventMonitor = nil
        }
        if let globalCaptureCancelEventMonitor {
            NSEvent.removeMonitor(globalCaptureCancelEventMonitor)
            self.globalCaptureCancelEventMonitor = nil
        }
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }

    func presentFloatingToolbar(
        for result: CaptureResult,
        document: AnnotationDocument,
        outputService: CaptureOutputService,
        ocrService: OCRService,
        shareService: ShareService,
        defaultSaveDirectory: URL,
        imageFormat: CaptureImageFormat,
        defaultOutputAction: CaptureOutputAction
    ) {
        let targetScreen = NSScreen.screens.first { $0.frame.intersects(result.selectionRect) } ?? NSScreen.main
        let screenFrame = targetScreen?.frame ?? result.selectionRect
        let inlineState = InlineCaptureEditorState(result: result, screenFrame: screenFrame, document: document)

        func finalizedResult() -> CaptureResult? {
            inlineState.finalizedResult()
        }

        func copyAndClose() {
            guard let finalized = finalizedResult() else { return }
            outputService.copy(result: finalized, document: document)
            inlineState.showFeedback("已复制到剪贴板")
            self.hideCaptureOverlay()
        }

        func save() {
            guard let finalized = finalizedResult() else { return }
            let token = inlineState.beginBusyAction(.save)
            _ = try? outputService.save(result: finalized, document: document, format: imageFormat, directory: defaultSaveDirectory)
            inlineState.showFeedback("已保存到默认目录")
            inlineState.endBusyAction(.save, token: token)
        }

        func saveAndClose() {
            save()
            self.hideCaptureOverlay()
        }

        func openEditor() {
            guard let finalized = finalizedResult() else { return }
            self.editorWindowController.show(result: finalized, document: document)
            self.hideCaptureOverlay()
        }

        func share() {
            guard let finalized = finalizedResult() else { return }
            let token = inlineState.beginBusyAction(.share)
            let item = try? outputService.prepareShareItem(
                result: finalized,
                document: document,
                format: imageFormat,
                directory: defaultSaveDirectory
            )
            guard let filePath = item?.savedFilePath else {
                inlineState.endBusyAction(.share, token: token)
                return
            }
            inlineState.showFeedback("已打开分享面板")
            shareService.share(fileURL: URL(fileURLWithPath: filePath))
            inlineState.endBusyAction(.share, token: token)
        }

        func recognizeText() {
            guard let image = inlineState.currentCroppedImage() else {
                inlineState.presentRecognizedText("")
                return
            }
            let token = inlineState.beginBusyAction(.ocr)

            Task { @MainActor in
                let text = (try? await ocrService.recognizeText(in: image)) ?? ""
                outputService.copyRecognizedText(text)
                inlineState.presentRecognizedText(text)
                inlineState.endBusyAction(.ocr, token: token)
            }
        }

        let content = InlineAnnotationEditorView(
            state: inlineState,
            onCopy: {
                copyAndClose()
            },
            onSave: {
                save()
            },
            onPin: {
                guard let finalized = finalizedResult() else { return }
                let rendered = AnnotationRenderer().render(baseImage: finalized.image, items: [])
                self.pinWindowController.show(image: rendered)
            },
            onEdit: {
                openEditor()
            },
            onOCR: {
                recognizeText()
            },
            onShare: {
                share()
            },
            onCancel: {
                self.hideCaptureOverlay()
            },
            onConfirm: {
                switch defaultOutputAction {
                case .copyOnly:
                    copyAndClose()
                case .saveOnly:
                    saveAndClose()
                case .copyAndSave:
                    save()
                    copyAndClose()
                case .openEditor:
                    openEditor()
                }
            }
        )

        hideCaptureOverlay()
        let hosting = NSHostingView(rootView: content)
        let window = CaptureOverlayWindow(contentView: hosting, frame: screenFrame)
        window.makeKeyAndOrderFront(nil)
        overlayWindows = [window]
    }
}
