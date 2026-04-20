import SwiftUI

struct MainWindowView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle)
            Text("Project bootstrap complete")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
    }
}
