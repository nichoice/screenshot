import Foundation

@MainActor
final class CaptureHotkeyHandler {
    private let hotkeyService: HotkeyService
    private let preferencesStore: AppPreferencesStore
    private let captureCoordinator: CaptureCoordinator

    init(
        hotkeyService: HotkeyService,
        preferencesStore: AppPreferencesStore,
        captureCoordinator: CaptureCoordinator
    ) {
        self.hotkeyService = hotkeyService
        self.preferencesStore = preferencesStore
        self.captureCoordinator = captureCoordinator
    }

    func start() throws {
        try hotkeyService.register(hotkey: preferencesStore.capturePreferences.hotkey) { [weak captureCoordinator] in
            Task { @MainActor in
                captureCoordinator?.beginCapture()
            }
        }
    }

    func reload() throws {
        hotkeyService.unregisterAll()
        try start()
    }
}
