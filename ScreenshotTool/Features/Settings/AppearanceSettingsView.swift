import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "主题",
                description: "控制整个 App 的外观模式。截图模式会单独保证高对比可见性。"
            ) {
                Picker("外观模式", selection: Binding(
                    get: { viewModel.appPreferences.themePreference },
                    set: viewModel.setThemePreference
                )) {
                    Text("浅色").tag(AppThemePreference.light)
                    Text("深色").tag(AppThemePreference.dark)
                    Text("跟随系统").tag(AppThemePreference.followSystem)
                }
                .pickerStyle(.segmented)
            }

            SettingsSectionCard(
                title: "预览",
                description: "主窗口、设置窗口、编辑窗口和工具条都共享这个主题。"
            ) {
                HStack(spacing: 12) {
                    previewSwatch("浅色", background: Color.white, foreground: Color.black.opacity(0.85))
                    previewSwatch("深色", background: Color.black.opacity(0.82), foreground: Color.white.opacity(0.9))
                    previewSwatch("系统", background: Color.secondary.opacity(0.18), foreground: Color.primary)
                }
            }
        }
    }

    private func previewSwatch(_ title: String, background: Color, foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(background)
                .frame(width: 120, height: 72)
                .overlay(
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule()
                            .fill(foreground.opacity(0.9))
                            .frame(width: 56, height: 10)
                        Capsule()
                            .fill(foreground.opacity(0.45))
                            .frame(width: 74, height: 8)
                    }
                    .padding(12),
                    alignment: .topLeading
                )
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
