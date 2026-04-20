import SwiftUI

struct ScreenshotSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Picker("Default action", selection: Binding(
                get: { viewModel.capturePreferences.defaultOutputAction },
                set: viewModel.setDefaultOutputAction
            )) {
                ForEach(CaptureOutputAction.allCases, id: \.self) { action in
                    Text(action.rawValue).tag(action)
                }
            }
        }
        .padding(24)
    }
}
