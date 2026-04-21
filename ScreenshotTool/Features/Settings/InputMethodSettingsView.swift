import SwiftUI

struct InputMethodSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel
    @State private var bundleIdentifier = ""
    @State private var appName = ""
    @State private var inputSourceID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionCard(
                title: "全局默认",
                description: "没有命中应用规则时，将回退到这里设置的输入法。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("启用输入法自动切换", isOn: Binding(
                        get: { viewModel.inputMethodPreferences.isEnabled },
                        set: viewModel.setInputMethodEnabled
                    ))

                    Picker("全局默认输入法", selection: Binding(
                        get: { viewModel.inputMethodPreferences.globalDefaultInputSourceID ?? "" },
                        set: { value in
                            viewModel.setGlobalInputSourceID(value.isEmpty ? nil : value)
                        }
                    )) {
                        Text("未设置").tag("")
                        ForEach(viewModel.availableInputSources) { source in
                            Text(source.localizedName).tag(source.id)
                        }
                    }

                    Text(globalSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSectionCard(
                title: "应用规则",
                description: "命中应用时优先使用规则输入法；未命中时再回退到全局默认。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.rules.isEmpty {
                        Text("还没有应用规则。可以为 IDE、浏览器、聊天工具等单独指定默认输入法。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.rules) { rule in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rule.appName)
                                                .font(.headline)
                                            Text(rule.bundleIdentifier)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Toggle("", isOn: Binding(
                                            get: { rule.isEnabled },
                                            set: { enabled in
                                                try? viewModel.setRuleEnabled(id: rule.id, enabled: enabled)
                                            }
                                        ))
                                        .labelsHidden()
                                    }

                                    HStack {
                                        Text("输入法")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(inputSourceName(for: rule.inputSourceID))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(14)
                                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("新增规则")
                            .font(.headline)
                        HStack {
                            TextField("Bundle ID", text: $bundleIdentifier)
                            TextField("应用名称", text: $appName)
                            TextField("输入源 ID", text: $inputSourceID)
                        }
                        Button("添加规则") {
                            try? viewModel.addRule(
                                bundleIdentifier: bundleIdentifier,
                                appName: appName,
                                inputSourceID: inputSourceID
                            )
                            bundleIdentifier = ""
                            appName = ""
                            inputSourceID = ""
                        }
                        .disabled(bundleIdentifier.isEmpty || appName.isEmpty || inputSourceID.isEmpty)
                    }
                }
            }
        }
    }

    private var globalSummary: String {
        if !viewModel.inputMethodPreferences.isEnabled {
            return "当前已关闭自动切换，所有应用都保持系统当前输入法。"
        }

        if let globalID = viewModel.inputMethodPreferences.globalDefaultInputSourceID {
            return "未命中应用规则时，统一切换到 \(inputSourceName(for: globalID))。"
        }

        return "当前没有设置全局默认输入法，仅在命中应用规则时切换。"
    }

    private func inputSourceName(for id: String) -> String {
        viewModel.availableInputSources.first(where: { $0.id == id })?.localizedName ?? id
    }
}
