import Foundation

@MainActor
final class CaptureHotkeyHandler {
    private let hotkeyService: HotkeyService
    private let preferencesStore: AppPreferencesStore
    private var startCapture: () -> Void

    init(
        hotkeyService: HotkeyService,
        preferencesStore: AppPreferencesStore,
        startCapture: @escaping () -> Void
    ) {
        self.hotkeyService = hotkeyService
        self.preferencesStore = preferencesStore
        self.startCapture = startCapture
    }

    func start() throws {
        try hotkeyService.register(hotkey: preferencesStore.capturePreferences.hotkey) { [weak self] in
            Task { @MainActor in
                self?.startCapture()
            }
        }
    }

    func reload() throws {
        hotkeyService.unregisterAll()
        try start()
    }

    func replaceStartCaptureAction(_ action: @escaping () -> Void) {
        startCapture = action
    }
}
