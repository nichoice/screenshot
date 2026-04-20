import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screenshot Tool")
                .font(.largeTitle)
            Text("Screen Recording: \(String(describing: viewModel.permissions.screenRecording))")
            Text("Accessibility: \(String(describing: viewModel.permissions.accessibility))")
            Button("Open Settings") {
                viewModel.openSettings()
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
        .onAppear {
            viewModel.refresh()
        }
    }
}
