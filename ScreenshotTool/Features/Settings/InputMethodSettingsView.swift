import SwiftUI

struct InputMethodSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel
    @State private var bundleIdentifier = ""
    @State private var appName = ""
    @State private var inputSourceID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable input method automation", isOn: Binding(
                get: { viewModel.inputMethodPreferences.isEnabled },
                set: viewModel.setInputMethodEnabled
            ))
            Picker("Global default input source", selection: Binding(
                get: { viewModel.inputMethodPreferences.globalDefaultInputSourceID ?? "" },
                set: { value in
                    viewModel.setGlobalInputSourceID(value.isEmpty ? nil : value)
                }
            )) {
                Text("None").tag("")
                ForEach(viewModel.availableInputSources) { source in
                    Text(source.localizedName).tag(source.id)
                }
            }
            List(viewModel.rules) { rule in
                HStack {
                    Text(rule.appName)
                    Spacer()
                    Text(rule.inputSourceID)
                }
            }
            HStack {
                TextField("Bundle ID", text: $bundleIdentifier)
                TextField("App Name", text: $appName)
                TextField("Input Source ID", text: $inputSourceID)
                Button("Add Rule") {
                    try? viewModel.addRule(
                        bundleIdentifier: bundleIdentifier,
                        appName: appName,
                        inputSourceID: inputSourceID
                    )
                    bundleIdentifier = ""
                    appName = ""
                    inputSourceID = ""
                }
            }
        }
        .padding(24)
    }
}
