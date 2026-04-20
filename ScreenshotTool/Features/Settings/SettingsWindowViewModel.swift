import Foundation

@MainActor
final class SettingsWindowViewModel: ObservableObject {
    let sidebarItems: [SettingsSidebarItem]

    private let preferencesStore: AppPreferencesStore
    private let rulesStore: InputMethodRulesStore
    private let inputSourceService: InputSourceService
    private let permissionsService: PermissionsService
    private let loginItemService: LoginItemService
    private let inputMethodManager: InputMethodManager

    @Published private(set) var appPreferences: AppPreferences
    @Published private(set) var capturePreferences: CapturePreferences
    @Published private(set) var annotationPreferences: AnnotationPreferences
    @Published private(set) var inputMethodPreferences: InputMethodPreferences
    @Published private(set) var rules: [AppInputMethodRule]
    @Published private(set) var availableInputSources: [InputSourceDescriptor]
    @Published private(set) var permissionSnapshot: PermissionsSnapshot
    @Published var selectedSidebarItemID: String?

    init(
        preferencesStore: AppPreferencesStore,
        rulesStore: InputMethodRulesStore,
        inputSourceService: InputSourceService,
        permissionsService: PermissionsService,
        loginItemService: LoginItemService,
        inputMethodManager: InputMethodManager
    ) {
        self.sidebarItems = SettingsSidebarItem.defaultItems
        self.preferencesStore = preferencesStore
        self.rulesStore = rulesStore
        self.inputSourceService = inputSourceService
        self.permissionsService = permissionsService
        self.loginItemService = loginItemService
        self.inputMethodManager = inputMethodManager
        self.appPreferences = preferencesStore.appPreferences
        self.capturePreferences = preferencesStore.capturePreferences
        self.annotationPreferences = preferencesStore.annotationPreferences
        self.inputMethodPreferences = preferencesStore.inputMethodPreferences
        self.rules = rulesStore.rules
        self.availableInputSources = inputSourceService.availableInputSources()
        self.permissionSnapshot = permissionsService.currentSnapshot()
        self.selectedSidebarItemID = self.sidebarItems.first?.id
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        try loginItemService.setLaunchAtLogin(enabled)
        preferencesStore.updateApp { $0.launchAtLogin = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setMenuBarIconVisible(_ enabled: Bool) {
        preferencesStore.updateApp { $0.showsMenuBarIcon = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setStayResident(_ enabled: Bool) {
        preferencesStore.updateApp { $0.stayResidentAfterClosingWindow = enabled }
        appPreferences = preferencesStore.appPreferences
    }

    func setDefaultOutputAction(_ action: CaptureOutputAction) {
        preferencesStore.updateCapture { $0.defaultOutputAction = action }
        capturePreferences = preferencesStore.capturePreferences
    }

    func setAnnotationLineWidth(_ width: Double) {
        preferencesStore.updateAnnotation { $0.defaultLineWidth = width }
        annotationPreferences = preferencesStore.annotationPreferences
    }

    func setInputMethodEnabled(_ enabled: Bool) {
        preferencesStore.updateInputMethod { $0.isEnabled = enabled }
        inputMethodPreferences = preferencesStore.inputMethodPreferences
    }

    func setGlobalInputSourceID(_ id: String?) {
        preferencesStore.updateInputMethod { $0.globalDefaultInputSourceID = id }
        inputMethodPreferences = preferencesStore.inputMethodPreferences
    }

    func setThemePreference(_ preference: AppThemePreference) {
        preferencesStore.updateApp { $0.themePreference = preference }
        appPreferences = preferencesStore.appPreferences
    }

    func addRule(bundleIdentifier: String, appName: String, inputSourceID: String) throws {
        let rule = AppInputMethodRule(
            id: UUID(),
            bundleIdentifier: bundleIdentifier,
            appName: appName,
            inputSourceID: inputSourceID,
            isEnabled: true
        )
        try rulesStore.upsert(rule)
        rules = rulesStore.rules
    }

    func removeRule(id: UUID) throws {
        try rulesStore.remove(id: id)
        rules = rulesStore.rules
    }

    var selectedSidebarItem: SettingsSidebarItem? {
        sidebarItems.first(where: { $0.id == selectedSidebarItemID })
    }

    var selectedPageTitle: String {
        selectedSidebarItem?.title ?? "设置"
    }

    var selectedPageDescription: String {
        selectedSidebarItem?.description ?? ""
    }

    var groupedSidebarItems: [(title: String, items: [SettingsSidebarItem])] {
        let order = ["基础", "截图", "输入法", "其他"]
        return order.compactMap { group in
            let items = sidebarItems.filter { $0.groupTitle == group }
            return items.isEmpty ? nil : (group, items)
        }
    }
}
