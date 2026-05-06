import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "应用行为",
                description: "Screenshot Tool 会以无 Dock 图标的方式后台常驻；这里可以决定是否额外保留菜单栏入口。"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    statusRow("后台驻留", value: "已启用，关闭窗口后快捷键仍可用")
                    statusRow("Dock 图标", value: "已隐藏")

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
                    statusRow("后台驻留", value: "已启用")
                    statusRow("Dock 图标", value: "已隐藏")
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
