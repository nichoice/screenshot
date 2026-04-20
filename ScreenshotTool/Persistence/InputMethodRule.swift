import Foundation

struct AppInputMethodRule: Codable, Equatable, Identifiable {
    let id: UUID
    var bundleIdentifier: String
    var appName: String
    var inputSourceID: String
    var isEnabled: Bool
}
