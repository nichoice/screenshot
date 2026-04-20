import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedSidebarItemID) {
                ForEach(viewModel.groupedSidebarItems, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.items) { item in
                            Label(item.title, systemImage: item.iconSystemName)
                                .tag(item.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.selectedPageTitle)
                            .font(.largeTitle)
                        if !viewModel.selectedPageDescription.isEmpty {
                            Text(viewModel.selectedPageDescription)
                                .foregroundStyle(.secondary)
                        }
                    }

                    pageView(for: viewModel.selectedSidebarItemID)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 960, height: 640)
    }

    @ViewBuilder
    private func pageView(for selection: String?) -> some View {
        switch selection {
        case "appearance":
            AppearanceSettingsView(viewModel: viewModel)
        case "capture":
            ScreenshotSettingsView(viewModel: viewModel)
        case "annotation":
            AnnotationSettingsView(viewModel: viewModel)
        case "input-method":
            InputMethodSettingsView(viewModel: viewModel)
        case "diagnostics":
            DiagnosticsSettingsView(viewModel: viewModel)
        default:
            GeneralSettingsView(viewModel: viewModel)
        }
    }
}
