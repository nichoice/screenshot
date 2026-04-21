import AppKit
import CoreGraphics
import Foundation

final class CaptureOutputService {
    private let renderer: AnnotationRenderer
    private let clipboardService: ClipboardService
    private let historyStore: CaptureHistoryStore
    private let cacheDirectory: URL

    init(
        renderer: AnnotationRenderer,
        clipboardService: ClipboardService,
        historyStore: CaptureHistoryStore,
        cacheDirectory: URL
    ) {
        self.renderer = renderer
        self.clipboardService = clipboardService
        self.historyStore = historyStore
        self.cacheDirectory = cacheDirectory
    }

    func copy(result: CaptureResult, document: AnnotationDocument) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        clipboardService.copy(image: rendered)
        let previewURL = try writePreview(rendered)
        let item = CaptureHistoryItem(
            id: UUID(),
            createdAt: result.capturedAt,
            previewFilePath: previewURL.path,
            savedFilePath: nil,
            didCopyToClipboard: true
        )
        try historyStore.append(item)
        return item
    }

    func save(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        let savedURL = try writeRenderedImage(rendered, format: format, directory: directory)

        let previewURL = try writePreview(rendered)
        let item = CaptureHistoryItem(
            id: UUID(),
            createdAt: result.capturedAt,
            previewFilePath: previewURL.path,
            savedFilePath: savedURL.path,
            didCopyToClipboard: false
        )
        try historyStore.append(item)
        return item
    }

    func prepareShareItem(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        let savedURL = try writeRenderedImage(rendered, format: format, directory: directory)
        let previewURL = try writePreview(rendered)
        let item = CaptureHistoryItem(
            id: UUID(),
            createdAt: result.capturedAt,
            previewFilePath: previewURL.path,
            savedFilePath: savedURL.path,
            didCopyToClipboard: false
        )
        try historyStore.append(item)
        return item
    }

    func copyRecognizedText(_ text: String) {
        clipboardService.copy(text: text)
    }

    private func writePreview(_ image: CGImage) throws -> URL {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let previewURL = cacheDirectory.appendingPathComponent("preview-\(UUID().uuidString).png")
        let nsImage = NSImage(cgImage: image, size: .zero)
        let representation = NSBitmapImageRep(data: nsImage.tiffRepresentation!)!
        let data = representation.representation(using: .png, properties: [:])!
        try data.write(to: previewURL, options: .atomic)
        return previewURL
    }

    private func writeRenderedImage(_ image: CGImage, format: CaptureImageFormat, directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let savedURL = directory.appendingPathComponent("capture-\(UUID().uuidString).\(format == .png ? "png" : "jpg")")
        let nsImage = NSImage(cgImage: image, size: .zero)
        let representation = NSBitmapImageRep(data: nsImage.tiffRepresentation!)!
        let data = representation.representation(using: format == .png ? .png : .jpeg, properties: [:])!
        try data.write(to: savedURL, options: .atomic)
        return savedURL
    }
}
