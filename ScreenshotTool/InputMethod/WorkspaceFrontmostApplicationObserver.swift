import AppKit
import Foundation

final class WorkspaceFrontmostApplicationObserver: FrontmostApplicationObserver {
    var onChange: ((String?) -> Void)?
    private var token: NSObjectProtocol?

    func start() {
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.onChange?(app?.bundleIdentifier)
        }
    }

    func stop() {
        if let token {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        token = nil
    }
}
