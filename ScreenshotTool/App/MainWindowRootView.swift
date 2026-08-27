import SwiftUI

struct MainWindowRootView: View {
    @ObservedObject var mainViewModel: MainWindowViewModel
    @ObservedObject var settingsViewModel: SettingsWindowViewModel
    let windowRouter: WindowRouter
    let startBatchCapture: () -> Void

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MainWindowView(
            mainViewModel: mainViewModel,
            settingsViewModel: settingsViewModel,
            startBatchCapture: startBatchCapture
        )
            .onAppear {
                windowRouter.configureOpenSettings {
                    openWindow(id: "settings")
                }
            }
    }
}
