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
                    permissionRow("屏幕录制", value: String(describing: viewModel.permissionSnapshot.screenRecording))
                    permissionRow("辅助功能", value: String(describing: viewModel.permissionSnapshot.accessibility))
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
    }

    private func permissionRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
