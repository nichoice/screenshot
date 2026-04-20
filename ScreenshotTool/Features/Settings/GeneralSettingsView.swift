import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Toggle("Stay resident after closing windows", isOn: Binding(
                get: { viewModel.appPreferences.stayResidentAfterClosingWindow },
                set: viewModel.setStayResident
            ))
            Toggle("Show menu bar icon", isOn: Binding(
                get: { viewModel.appPreferences.showsMenuBarIcon },
                set: viewModel.setMenuBarIconVisible
            ))
        }
        .padding(24)
    }
}
