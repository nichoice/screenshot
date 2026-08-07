import AppKit
import CoreGraphics
import Foundation
import ImageIO

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

    func copy(result: CaptureResult, document: AnnotationDocument) {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        copyRenderedImage(rendered)
    }

    func save(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        return try saveRenderedImage(rendered, capturedAt: result.capturedAt, format: format, directory: directory)
    }

    func prepareShareItem(result: CaptureResult, document: AnnotationDocument, format: CaptureImageFormat, directory: URL) throws -> CaptureHistoryItem {
        let rendered = renderer.render(baseImage: result.image, items: document.items)
        return try saveRenderedImage(rendered, capturedAt: result.capturedAt, format: format, directory: directory)
    }

    func copyRenderedImage(_ image: CGImage) {
        clipboardService.copy(image: image)
    }

    func saveRenderedImage(
        _ image: CGImage,
        capturedAt: Date,
        format: CaptureImageFormat,
        directory: URL
    ) throws -> CaptureHistoryItem {
        let savedURL = try writeRenderedImage(image, format: format, directory: directory)
        let previewURL: URL
        if format == .png {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            previewURL = cacheDirectory.appendingPathComponent("preview-\(UUID().uuidString).png")
            try FileManager.default.copyItem(at: savedURL, to: previewURL)
        } else {
            previewURL = try writePreview(image)
        }
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
        guard let data = CaptureImageDataEncoder.encodePNG(image) else {
            throw CaptureOutputError.encodingFailed
        }
        try data.write(to: previewURL, options: .atomic)
        return previewURL
    }

    private func writeRenderedImage(_ image: CGImage, format: CaptureImageFormat, directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let savedURL = directory.appendingPathComponent("capture-\(UUID().uuidString).\(format == .png ? "png" : "jpg")")
        guard let data = CaptureImageDataEncoder.encode(image, format: format) else {
            throw CaptureOutputError.encodingFailed
        }
        try data.write(to: savedURL, options: .atomic)
        return savedURL
    }
}

private enum CaptureOutputError: Error {
    case encodingFailed
}

enum CaptureImageDataEncoder {
    static func encodePNG(_ image: CGImage) -> Data? {
        encode(image, type: "public.png")
    }

    static func encode(_ image: CGImage, format: CaptureImageFormat) -> Data? {
        encode(image, type: format == .png ? "public.png" : "public.jpeg")
    }

    private static func encode(_ image: CGImage, type: String) -> Data? {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                type as CFString,
                1,
                nil
            )
        else {
            return nil
        }

        var properties: [String: Any] = [:]
        if type == "public.jpeg" {
            properties[kCGImageDestinationLossyCompressionQuality as String] = 0.9
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}
