import SwiftUI

struct MainWindowRootView: View {
    @ObservedObject var mainViewModel: MainWindowViewModel
    @ObservedObject var settingsViewModel: SettingsWindowViewModel
    let windowRouter: WindowRouter

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MainWindowView(
            mainViewModel: mainViewModel,
            settingsViewModel: settingsViewModel
        )
            .onAppear {
                windowRouter.configureOpenSettings {
                    openWindow(id: "settings")
                }
            }
    }
}
