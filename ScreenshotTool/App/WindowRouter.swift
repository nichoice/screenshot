import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
