import AppKit
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

                    Toggle(
                        "播放截图提示音",
                        isOn: Binding(
                            get: { viewModel.capturePreferences.playCaptureSound },
                            set: viewModel.setPlayCaptureSound
                        )
                    )
                }
            }

            SettingsSectionCard(
                title: "输出",
                description: "配置保存类截图的默认目录；仅复制的截图只进入剪切板，不写入文件或历史。"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        infoRow("默认保存目录", value: saveDirectoryDisplayPath)
                        Spacer()
                        Button("选择目录...") {
                            chooseSaveDirectory()
                        }
                    }
                    infoRow("完成后动作", value: outputSummary(viewModel.capturePreferences.defaultOutputAction))
                    infoRow("文件格式", value: viewModel.capturePreferences.imageFormat == .png ? "PNG 无损" : "JPEG 压缩")
                    infoRow("提示音", value: viewModel.capturePreferences.playCaptureSound ? "完成截图后播放系统提示音" : "静音")
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

    private var saveDirectoryDisplayPath: String {
        viewModel.capturePreferences.defaultSaveDirectoryPath
            ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].path
    }

    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择"
        panel.directoryURL = URL(fileURLWithPath: saveDirectoryDisplayPath)

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.setDefaultSaveDirectory(url)
        }
    }

    private func outputSummary(_ action: CaptureOutputAction) -> String {
        switch action {
        case .copyOnly:
            "截图后立即复制到剪贴板，不保存文件，不写历史"
        case .saveOnly:
            "截图后直接保存到默认目录"
        case .copyAndSave:
            "同时复制到剪贴板并写入默认目录"
        case .openEditor:
            "截图后先打开编辑器再决定导出方式"
        }
    }
}
