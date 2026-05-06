import Combine
import Foundation

@MainActor
final class MainWindowViewModel: ObservableObject {
    private let preferencesStore: AppPreferencesStore
    private let permissionsService: PermissionsService
    private let windowRouter: WindowRouter
    private var startCaptureAction: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var permissions: PermissionsSnapshot
    @Published private(set) var recentCaptures: [CaptureHistoryItem] = []

    init(
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        permissionsService: PermissionsService,
        windowRouter: WindowRouter,
        historyStore: CaptureHistoryStore,
        startCaptureAction: @escaping () -> Void = {}
    ) {
        self.preferencesStore = preferencesStore
        self.permissionsService = permissionsService
        self.windowRouter = windowRouter
        self.startCaptureAction = startCaptureAction
        self.permissions = permissionsService.currentSnapshot()
        preferencesStore.$capturePreferences
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        permissions = permissionsService.currentSnapshot()
        recentCaptures = []
    }

    func openSettings() {
        windowRouter.openSettings()
    }

    func startCapture() {
        startCaptureAction()
    }

    func replaceStartCaptureAction(_ action: @escaping () -> Void) {
        startCaptureAction = action
    }

    var shortcutSummary: String {
        preferencesStore.capturePreferences.hotkey.displayName
    }

    var primarySectionTitle: String {
        "通用"
    }
}
