import SwiftUI

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let description: String?
    @ViewBuilder var content: Content

    init(title: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        GlassSurface {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    if let description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
