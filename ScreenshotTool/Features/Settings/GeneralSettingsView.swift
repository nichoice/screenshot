import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "应用行为",
                description: "决定主窗口关闭后是否继续常驻，以及是否保留菜单栏入口。"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("关闭窗口后继续后台驻留", isOn: Binding(
                        get: { viewModel.appPreferences.stayResidentAfterClosingWindow },
                        set: viewModel.setStayResident
                    ))

                    Toggle("显示菜单栏图标", isOn: Binding(
                        get: { viewModel.appPreferences.showsMenuBarIcon },
                        set: viewModel.setMenuBarIconVisible
                    ))
                }
            }

            SettingsSectionCard(
                title: "运行状态",
                description: "快速确认当前常驻形态、主题策略和输入法自动化是否生效。"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    statusRow("后台驻留", value: viewModel.appPreferences.stayResidentAfterClosingWindow ? "已启用" : "关闭窗口时退出")
                    statusRow("菜单栏入口", value: viewModel.appPreferences.showsMenuBarIcon ? "已显示" : "已隐藏")
                    statusRow("当前主题策略", value: themeLabel(viewModel.appPreferences.themePreference))
                    statusRow("输入法自动切换", value: viewModel.inputMethodPreferences.isEnabled ? "已启用" : "未启用")
                }
            }
        }
    }

    private func statusRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func themeLabel(_ preference: AppThemePreference) -> String {
        switch preference {
        case .light:
            "浅色"
        case .dark:
            "深色"
        case .followSystem:
            "跟随系统"
        }
    }
}
