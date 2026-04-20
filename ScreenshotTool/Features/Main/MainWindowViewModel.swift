import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter

    @Published private(set) var permissions: PermissionsSnapshot

    init(permissionsService: PermissionsService, windowRouter: WindowRouter) {
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.permissions = permissionsService.currentSnapshot()
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
    }

    func openSettings() {
        windowRouter.openSettings()
    }
}
