import SwiftUI

struct AnnotationSettingsView: View {
    @ObservedObject var viewModel: SettingsWindowViewModel

    var body: some View {
        Form {
            Slider(
                value: Binding(
                    get: { viewModel.annotationPreferences.defaultLineWidth },
                    set: viewModel.setAnnotationLineWidth
                ),
                in: 1...12
            ) {
                Text("Default line width")
            }
        }
        .padding(24)
    }
}
