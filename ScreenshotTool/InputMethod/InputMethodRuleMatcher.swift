import Foundation

enum InputMethodResolutionSource: Equatable {
    case disabled
    case appRule
    case globalDefault
    case none
}

struct InputMethodResolution: Equatable {
    let bundleIdentifier: String?
    let targetInputSourceID: String?
    let source: InputMethodResolutionSource
}

struct InputMethodRuleMatcher {
    func resolve(
        bundleIdentifier: String?,
        preferences: InputMethodPreferences,
        rules: [AppInputMethodRule]
    ) -> InputMethodResolution {
        guard preferences.isEnabled else {
            return InputMethodResolution(
                bundleIdentifier: bundleIdentifier,
                targetInputSourceID: nil,
                source: .disabled
            )
        }

        if let bundleIdentifier,
           let rule = rules.first(where: { $0.bundleIdentifier == bundleIdentifier && $0.isEnabled }) {
            return InputMethodResolution(
                bundleIdentifier: bundleIdentifier,
                targetInputSourceID: rule.inputSourceID,
                source: .appRule
            )
        }

        if let globalID = preferences.globalDefaultInputSourceID {
            return InputMethodResolution(
                bundleIdentifier: bundleIdentifier,
                targetInputSourceID: globalID,
                source: .globalDefault
            )
        }

        return InputMethodResolution(
            bundleIdentifier: bundleIdentifier,
            targetInputSourceID: nil,
            source: .none
        )
    }
}
