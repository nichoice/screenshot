import Foundation

final class AppPreferencesStore: ObservableObject {
    private enum Key: String {
        case app
        case capture
        case annotation
        case inputMethod
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()

    @Published private(set) var appPreferences: AppPreferences
    @Published private(set) var capturePreferences: CapturePreferences
    @Published private(set) var annotationPreferences: AnnotationPreferences
    @Published private(set) var inputMethodPreferences: InputMethodPreferences

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.appPreferences = Self.load(AppPreferences.self, key: .app, from: userDefaults) ?? AppPreferences()
        self.capturePreferences = Self.load(CapturePreferences.self, key: .capture, from: userDefaults) ?? CapturePreferences()
        self.annotationPreferences = Self.load(AnnotationPreferences.self, key: .annotation, from: userDefaults) ?? AnnotationPreferences()
        self.inputMethodPreferences = Self.load(InputMethodPreferences.self, key: .inputMethod, from: userDefaults) ?? InputMethodPreferences()
        migrateLegacyCaptureHotkeyIfNeeded()
        migrateDefaultSaveDirectoryIfNeeded()
    }

    func updateApp(_ mutate: (inout AppPreferences) -> Void) {
        mutate(&appPreferences)
        save(appPreferences, key: .app)
    }

    func updateCapture(_ mutate: (inout CapturePreferences) -> Void) {
        mutate(&capturePreferences)
        save(capturePreferences, key: .capture)
    }

    func updateAnnotation(_ mutate: (inout AnnotationPreferences) -> Void) {
        mutate(&annotationPreferences)
        save(annotationPreferences, key: .annotation)
    }

    func updateInputMethod(_ mutate: (inout InputMethodPreferences) -> Void) {
        mutate(&inputMethodPreferences)
        save(inputMethodPreferences, key: .inputMethod)
    }

    private func save<T: Encodable>(_ value: T, key: Key) {
        let data = try! encoder.encode(value)
        userDefaults.set(data, forKey: key.rawValue)
    }

    private func migrateLegacyCaptureHotkeyIfNeeded() {
        let legacyDefaultCapture = GlobalHotkey(keyCode: 23, modifiers: [.command, .shift])
        guard capturePreferences.hotkey == legacyDefaultCapture else { return }
        capturePreferences.hotkey = .defaultCapture
        save(capturePreferences, key: .capture)
    }

    private func migrateDefaultSaveDirectoryIfNeeded() {
        guard capturePreferences.defaultSaveDirectoryPath == nil else { return }
        capturePreferences.defaultSaveDirectoryPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path
        save(capturePreferences, key: .capture)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: Key, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }
}
