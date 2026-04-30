import Foundation

@MainActor
final class InputMethodManager: ObservableObject {
    private let preferencesStore: AppPreferencesStore
    private let rulesStore: InputMethodRulesStore
    private let inputSourceService: InputSourceService
    private let matcher: InputMethodRuleMatcher
    private var observer: FrontmostApplicationObserver?

    @Published private(set) var status = InputMethodAutomationStatus()

    init(
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        inputSourceService: InputSourceService,
        matcher: InputMethodRuleMatcher,
        observer: FrontmostApplicationObserver? = nil
    ) {
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.inputSourceService = inputSourceService
        self.matcher = matcher
        self.observer = observer
    }

    func startObserving() {
        observer?.onChange = { [weak self] bundleIdentifier in
            Task { @MainActor in
                self?.handleFrontmostApplicationChange(bundleIdentifier: bundleIdentifier)
            }
        }
        observer?.start()
    }

    func stopObserving() {
        observer?.stop()
    }

    func handleFrontmostApplicationChange(bundleIdentifier: String?) {
        let resolution = matcher.resolve(
            bundleIdentifier: bundleIdentifier,
            preferences: preferencesStore.inputMethodPreferences,
            rules: rulesStore.rules
        )

        guard let target = resolution.targetInputSourceID else {
            status = InputMethodAutomationStatus(
                lastBundleIdentifier: bundleIdentifier,
                lastTargetInputSourceID: nil,
                lastSwitchSucceeded: nil
            )
            return
        }

        if inputSourceService.currentInputSourceID() == target {
            status = InputMethodAutomationStatus(
                lastBundleIdentifier: bundleIdentifier,
                lastTargetInputSourceID: target,
                lastSwitchSucceeded: true
            )
            return
        }

        let succeeded = inputSourceService.selectInputSource(id: target)
        status = InputMethodAutomationStatus(
            lastBundleIdentifier: bundleIdentifier,
            lastTargetInputSourceID: target,
            lastSwitchSucceeded: succeeded
        )
    }

    #if DEBUG
    func simulateFrontmostApplicationChangeForTesting(bundleIdentifier: String?) {
        observer?.onChange?(bundleIdentifier)
    }
    #endif
}
