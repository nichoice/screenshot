import SwiftUI

struct MainWindowView: View {
    @ObservedObject var mainViewModel: MainWindowViewModel
    @ObservedObject var settingsViewModel: SettingsWindowViewModel

    var body: some View {
        SettingsWindowView(
            viewModel: settingsViewModel,
            leadingContent: AnyView(
                Group {
                    if settingsViewModel.selectedSidebarItemID == "general" || settingsViewModel.selectedSidebarItemID == nil {
                        MainDashboardCard(viewModel: mainViewModel)
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

                    Text(viewModel.shortcutSummary)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            SettingsSectionCard(
                title: "运行状态",
                description: "在这里快速确认权限、快捷键和最近截图。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 24) {
                        statusBlock("屏幕录制", value: String(describing: viewModel.permissions.screenRecording))
                        statusBlock("辅助功能", value: String(describing: viewModel.permissions.accessibility))
                        statusBlock("截图快捷键", value: viewModel.shortcutSummary)
                    }

                    Divider()

                    if viewModel.recentCaptures.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("还没有截图记录")
                                .font(.headline)
                            Text("从上方按钮开始截图后，最近记录会直接显示在这里。")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.recentCaptures.prefix(5)) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.previewFilePath)
                                            .font(.headline)
                                        Text(item.savedFilePath ?? "仅复制到剪贴板")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
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
