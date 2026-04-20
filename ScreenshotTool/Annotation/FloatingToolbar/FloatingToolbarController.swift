import AppKit
import SwiftUI

@MainActor
final class FloatingToolbarController {
    private var panel: NSPanel?

    func show(
        frame: CGRect,
        copyAction: @escaping () -> Void,
        saveAction: @escaping () -> Void,
        pinAction: @escaping () -> Void,
        editAction: @escaping () -> Void
    ) {
        let content = FloatingToolbarView(
            copyAction: copyAction,
            saveAction: saveAction,
            pinAction: pinAction,
            editAction: editAction
        )
        let hosting = NSHostingView(rootView: content)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}

private struct FloatingToolbarView: View {
    let copyAction: () -> Void
    let saveAction: () -> Void
    let pinAction: () -> Void
    let editAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            FloatingToolbarButton(title: "复制", systemImage: "doc.on.doc", action: copyAction)
            FloatingToolbarButton(title: "保存", systemImage: "square.and.arrow.down", action: saveAction)
            FloatingToolbarButton(title: "钉住", systemImage: "pin", action: pinAction)
            FloatingToolbarButton(title: "编辑", systemImage: "pencil.tip.crop.circle", action: editAction)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(toolbarGlass)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 10)
        .padding(8)
    }

    @ViewBuilder
    private var toolbarGlass: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        shape
            .fill(.regularMaterial)
            .overlay(shape.fill(Color.black.opacity(0.2)))
            .modifier(LiquidGlassSurface(shape: shape))
    }
}

private struct FloatingToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .buttonStyle(.borderless)
        .background(.white.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .contentShape(Capsule())
    }
}

private struct LiquidGlassSurface<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content
        }
    }
}
