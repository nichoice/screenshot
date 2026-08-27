import SwiftUI

struct MainWindowView: View {
    @ObservedObject var mainViewModel: MainWindowViewModel
    @ObservedObject var settingsViewModel: SettingsWindowViewModel
    let startBatchCapture: () -> Void

    var body: some View {
        SettingsWindowView(
            viewModel: settingsViewModel,
            leadingContent: AnyView(
                Group {
                    if settingsViewModel.selectedSidebarItemID == "general" || settingsViewModel.selectedSidebarItemID == nil {
                        MainDashboardCard(
                            viewModel: mainViewModel,
                            startBatchCapture: startBatchCapture
                        )
                    }
                }
            )
        )
        .onAppear {
            settingsViewModel.selectedSidebarItemID = "general"
            mainViewModel.refresh()
        }
    }
}

private struct MainDashboardCard: View {
    @ObservedObject var viewModel: MainWindowViewModel
    let startBatchCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "开始截图",
                description: "主界面的第一优先动作。也可以继续使用全局快捷键直接唤起截图。"
            ) {
                HStack(spacing: 12) {
                    Button("开始截图") {
                        viewModel.startCapture()
                    }
                    .keyboardShortcut(.space, modifiers: [.command, .shift])
                    .buttonStyle(.borderedProminent)

                    Button("连续截图") {
                        startBatchCapture()
                    }
                    .buttonStyle(.bordered)

                    Text(viewModel.shortcutSummary)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            SettingsSectionCard(
                title: "运行状态",
                description: "在这里快速确认权限、快捷键和当前运行状态。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 24) {
                        statusBlock("屏幕录制", value: viewModel.permissions.screenRecording.displayName)
                        statusBlock("辅助功能", value: viewModel.permissions.accessibility.displayName)
                        statusBlock("截图快捷键", value: viewModel.shortcutSummary)
                    }
                }
            }
        }
    }

    private func statusBlock(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
