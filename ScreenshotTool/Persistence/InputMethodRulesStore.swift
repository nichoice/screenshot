import Foundation

final class InputMethodRulesStore: ObservableObject {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var rules: [AppInputMethodRule]

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([AppInputMethodRule].self, from: data) {
            self.rules = decoded
        } else {
            self.rules = []
        }
    }

    func upsert(_ rule: AppInputMethodRule) throws {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }

        try save()
    }

    func remove(id: UUID) throws {
        rules.removeAll { $0.id == id }
        try save()
    }

    private func save() throws {
        let data = try encoder.encode(rules)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
