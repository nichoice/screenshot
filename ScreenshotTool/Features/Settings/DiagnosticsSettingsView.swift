import SwiftUI

struct DiagnosticsSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "系统权限",
                description: "截图和自动切换输入法都依赖系统权限。"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    permissionRow(
                        "屏幕录制",
                        value: viewModel.permissionSnapshot.screenRecording.displayName,
                        actionTitle: "打开设置",
                        action: viewModel.openScreenRecordingSettings
                    )
                    permissionRow(
                        "辅助功能",
                        value: viewModel.permissionSnapshot.accessibility.displayName,
                        actionTitle: "打开设置",
                        action: viewModel.openAccessibilitySettings
                    )

                    Button("重新检查权限") {
                        viewModel.refreshPermissions()
                    }

                    Text("如果系统设置里已经打开，但这里仍显示未授权，请确认系统设置中授权的是当前正在运行的 ScreenshotTool.app。Debug 版本通常位于项目的 .build/xcode/Build/Products/Debug 目录。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("当前运行 App：\(Bundle.main.bundlePath)")
                        .font(.caption)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSectionCard(
                title: "运行状态",
                description: "用于快速判断当前功能是否已经处于可用状态。"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("输入法自动切换：\(viewModel.inputMethodPreferences.isEnabled ? "已启用" : "未启用")")
                    Text("应用规则数量：\(viewModel.rules.count)")
                    Text("可用输入源：\(viewModel.availableInputSources.count)")
                }
                .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.refreshPermissions()
        }
    }

    private func permissionRow(
        _ title: String,
        value: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
            Button(actionTitle) {
                action()
            }
        }
    }
}
