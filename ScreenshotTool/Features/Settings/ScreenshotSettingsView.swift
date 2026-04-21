import SwiftUI

struct ScreenshotSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "捕获",
                description: "控制截图热键后的默认处理方式和文件输出格式。"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    infoRow("截图快捷键", value: "Command + Shift + 4")

                    Picker("默认动作", selection: Binding(
                        get: { viewModel.capturePreferences.defaultOutputAction },
                        set: viewModel.setDefaultOutputAction
                    )) {
                        Text("仅复制").tag(CaptureOutputAction.copyOnly)
                        Text("仅保存").tag(CaptureOutputAction.saveOnly)
                        Text("复制并保存").tag(CaptureOutputAction.copyAndSave)
                        Text("进入编辑").tag(CaptureOutputAction.openEditor)
                    }
                    .pickerStyle(.segmented)

                    Picker("图片格式", selection: Binding(
                        get: { viewModel.capturePreferences.imageFormat },
                        set: viewModel.setImageFormat
                    )) {
                        Text("PNG").tag(CaptureImageFormat.png)
                        Text("JPEG").tag(CaptureImageFormat.jpeg)
                    }
                    .pickerStyle(.segmented)
                }
            }

            SettingsSectionCard(
                title: "输出",
                description: "展示当前默认输出路径，以及捕获完成后的处理摘要。"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow("默认保存目录", value: viewModel.capturePreferences.defaultSaveDirectoryPath ?? "系统图片目录 / ScreenshotTool")
                    infoRow("完成后动作", value: outputSummary(viewModel.capturePreferences.defaultOutputAction))
                    infoRow("文件格式", value: viewModel.capturePreferences.imageFormat == .png ? "PNG 无损" : "JPEG 压缩")
                }
            }
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func outputSummary(_ action: CaptureOutputAction) -> String {
        switch action {
        case .copyOnly:
            "截图后立即复制到剪贴板"
        case .saveOnly:
            "截图后直接保存到默认目录"
        case .copyAndSave:
            "同时复制到剪贴板并写入默认目录"
        case .openEditor:
            "截图后先打开编辑器再决定导出方式"
        }
    }
}
