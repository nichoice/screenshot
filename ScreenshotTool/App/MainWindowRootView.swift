import SwiftUI

struct MainWindowRootView: View {
    @ObservedObject var viewModel: MainWindowViewModel
    let windowRouter: WindowRouter

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MainWindowView(viewModel: viewModel)
            .onAppear {
                windowRouter.configureOpenSettings {
                    openWindow(id: "settings")
                }
            }
    }
}
