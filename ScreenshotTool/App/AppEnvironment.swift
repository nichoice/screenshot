import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let windowTitle: String

    init(windowTitle: String = "Screenshot Tool") {
        self.windowTitle = windowTitle
    }

    static func bootstrap() -> AppEnvironment {
        AppEnvironment()
    }

    static func bootstrapForTests() -> AppEnvironment {
        AppEnvironment()
    }
}
