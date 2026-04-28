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
        return try copyRenderedImage(rendered, capturedAt: result.capturedAt)
    }

    func save(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        return try saveRenderedImage(rendered, capturedAt: result.capturedAt, format: format, directory: directory)
    }

    func prepareShareItem(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        return try saveRenderedImage(rendered, capturedAt: result.capturedAt, format: format, directory: directory)
    }

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
