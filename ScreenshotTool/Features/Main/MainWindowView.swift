import SwiftUI

struct MainWindowView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Screenshot Tool")
                    .font(.largeTitle)
                Text("Capture, annotate, copy, save, and manage input method rules from one place.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Start Capture") {
                    viewModel.startCapture()
                }
                .keyboardShortcut(.space, modifiers: [.command, .shift])

                Button("Open Settings") {
                    viewModel.openSettings()
                }

                Spacer()
            }

            GroupBox {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen Recording")
                            .font(.headline)
                        Text(verbatim: String(describing: viewModel.permissions.screenRecording))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility")
                            .font(.headline)
                        Text(verbatim: String(describing: viewModel.permissions.accessibility))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("截图快捷键")
                            .font(.headline)
                        Text(viewModel.shortcutSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text("Permissions")
            }

            GroupBox {
                if viewModel.recentCaptures.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No captures yet")
                            .font(.headline)
                        Text("Use Start Capture or your global shortcut to create the first screenshot.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else {
                    List(viewModel.recentCaptures) { item in
                        VStack(alignment: .leading) {
                            Text(item.previewFilePath)
                            Text(item.savedFilePath ?? "Copied only")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: 220)
                }
            } label: {
                Text("Recent Captures")
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 720, minHeight: 480)
        .padding(24)
        .onAppear {
            viewModel.refresh()
        }
    }
}
