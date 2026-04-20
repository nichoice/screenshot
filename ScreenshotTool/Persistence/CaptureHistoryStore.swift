import Foundation

final class CaptureHistoryStore: ObservableObject {
    private let fileURL: URL
    private var limit: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var items: [CaptureHistoryItem]

    init(fileURL: URL, limit: Int) {
        self.fileURL = fileURL
        self.limit = limit
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([CaptureHistoryItem].self, from: data) {
            self.items = decoded
        } else {
            self.items = []
        }
    }

    func setLimit(_ limit: Int) throws {
        self.limit = limit
        try trimAndSave()
    }

    func append(_ item: CaptureHistoryItem) throws {
        items.insert(item, at: 0)
        try trimAndSave()
    }

    private func trimAndSave() throws {
        items = Array(items.prefix(limit))
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
