import SwiftUI

struct AnnotationSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "默认样式",
                description: "控制新建标注时的默认线宽和文字字号。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("默认线宽")
                            Spacer()
                            Text("\(Int(viewModel.annotationPreferences.defaultLineWidth.rounded())) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { viewModel.annotationPreferences.defaultLineWidth },
                                set: viewModel.setAnnotationLineWidth
                            ),
                            in: 1...12,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("默认文字大小")
                            Spacer()
                            Text("\(Int(viewModel.annotationPreferences.defaultFontSize.rounded())) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { viewModel.annotationPreferences.defaultFontSize },
                                set: viewModel.setAnnotationFontSize
                            ),
                            in: 12...30,
                            step: 1
                        )
                    }
                }
            }

            SettingsSectionCard(
                title: "编辑行为",
                description: "定义编辑器是否保持上次工具，以及贴图窗口的默认层级。"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("记住上次使用的工具", isOn: Binding(
                        get: { viewModel.annotationPreferences.rememberLastTool },
                        set: viewModel.setRememberLastTool
                    ))
                    Toggle("贴图窗口默认保持置顶", isOn: Binding(
                        get: { viewModel.annotationPreferences.pinWindowsFloatOnTop },
                        set: viewModel.setPinWindowsFloatOnTop
                    ))
                }
            }
        }
    }
}
