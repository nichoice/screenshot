import Foundation

struct CaptureHistoryItem: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let previewFilePath: String
    let savedFilePath: String?
    let didCopyToClipboard: Bool
}
