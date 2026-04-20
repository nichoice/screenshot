import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter
    private let historyStore: CaptureHistoryStore

    @Published private(set) var permissions: PermissionsSnapshot
    @Published private(set) var recentCaptures: [CaptureHistoryItem] = []

    init(permissionsService: PermissionsService, windowRouter: WindowRouter, historyStore: CaptureHistoryStore) {
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.historyStore = historyStore
        self.permissions = permissionsService.currentSnapshot()
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
        recentCaptures = historyStore.items
    }

    func openSettings() {
        windowRouter.openSettings()
    }
}
