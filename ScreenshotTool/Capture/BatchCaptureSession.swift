import CoreGraphics
import Foundation

struct BatchCaptureItem: Identifiable, Equatable {
    let id: UUID
    let capturedAt: Date
    let fileURL: URL
    let pixelSize: CGSize
}

@MainActor
final class BatchCaptureSession {
    enum SessionError: Error, Equatable {
        case notActive
        case maximumItemCountReached
        case imageEncodingFailed
    }

    private let rootDirectory: URL
    private let maximumItemCount: Int
    private let fileManager: FileManager

    private(set) var items: [BatchCaptureItem] = []
    private(set) var isActive = false
    private var activeDirectory: URL?
    private var retainedClipboardDirectory: URL?

    init(
        rootDirectory: URL,
        maximumItemCount: Int = 20,
        fileManager: FileManager = .default
    ) {
        self.rootDirectory = rootDirectory
        self.maximumItemCount = maximumItemCount
        self.fileManager = fileManager
    }

    var itemCount: Int {
        items.count
    }

    func begin() throws {
        discardActiveSession()
        discardRetainedClipboardFiles()
        try? fileManager.removeItem(at: rootDirectory)

        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let directory = rootDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        activeDirectory = directory
        isActive = true
    }

    func append(image: CGImage, capturedAt: Date) throws -> BatchCaptureItem {
        guard isActive, let activeDirectory else {
            throw SessionError.notActive
        }
        guard items.count < maximumItemCount else {
            throw SessionError.maximumItemCountReached
        }
        guard let data = CaptureImageDataEncoder.encodePNG(image) else {
            throw SessionError.imageEncodingFailed
        }

        let item = BatchCaptureItem(
            id: UUID(),
            capturedAt: capturedAt,
            fileURL: activeDirectory.appendingPathComponent("capture-\(items.count + 1).png"),
            pixelSize: CGSize(width: image.width, height: image.height)
        )
        try data.write(to: item.fileURL, options: .atomic)
        items.append(item)
        return item
    }

    func remove(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        try? fileManager.removeItem(at: item.fileURL)
    }

    func finish() -> [BatchCaptureItem] {
        guard isActive else { return [] }

        isActive = false
        retainedClipboardDirectory = activeDirectory
        activeDirectory = nil
        let completedItems = items
        items.removeAll()
        return completedItems
    }

    func cancel() {
        discardActiveSession()
    }

    func clearAllTemporaryFiles() {
        discardActiveSession()
        discardRetainedClipboardFiles()
        try? fileManager.removeItem(at: rootDirectory)
    }

    private func discardActiveSession() {
        if let activeDirectory {
            try? fileManager.removeItem(at: activeDirectory)
        }
        activeDirectory = nil
        items.removeAll()
        isActive = false
    }

    private func discardRetainedClipboardFiles() {
        if let retainedClipboardDirectory {
            try? fileManager.removeItem(at: retainedClipboardDirectory)
        }
        retainedClipboardDirectory = nil
    }
}
