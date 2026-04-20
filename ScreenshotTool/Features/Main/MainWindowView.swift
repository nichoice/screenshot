import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screenshot Tool")
                .font(.largeTitle)
            Text("Recent captures")
                .font(.headline)
            List(viewModel.recentCaptures) { item in
                VStack(alignment: .leading) {
                    Text(item.previewFilePath)
                    Text(item.savedFilePath ?? "Copied only")
                        .foregroundStyle(.secondary)
                }
            }
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
