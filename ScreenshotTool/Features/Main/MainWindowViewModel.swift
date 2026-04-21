import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter
    private let historyStore: CaptureHistoryStore
    private let startCaptureAction: () -> Void

    @Published private(set) var permissions: PermissionsSnapshot
    @Published private(set) var recentCaptures: [CaptureHistoryItem] = []

    init(
        permissionsService: PermissionsService,
        windowRouter: WindowRouter,
        historyStore: CaptureHistoryStore,
        startCaptureAction: @escaping () -> Void = {}
    ) {
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.historyStore = historyStore
        self.startCaptureAction = startCaptureAction
        self.permissions = permissionsService.currentSnapshot()
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
        recentCaptures = historyStore.items
    }

    func openSettings() {
        windowRouter.openSettings()
    }

    func startCapture() {
        startCaptureAction()
    }

    var shortcutSummary: String {
        "Command + Shift + 4"
    }

    var primarySectionTitle: String {
        "通用"
    }
}
