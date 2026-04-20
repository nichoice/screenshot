import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Text("General") }
            ScreenshotSettingsView(viewModel: viewModel)
                .tabItem { Text("Screenshot") }
            AnnotationSettingsView(viewModel: viewModel)
                .tabItem { Text("Annotation") }
            InputMethodSettingsView(viewModel: viewModel)
                .tabItem { Text("Input Method") }
        }
        .frame(width: 720, height: 520)
    }
}
