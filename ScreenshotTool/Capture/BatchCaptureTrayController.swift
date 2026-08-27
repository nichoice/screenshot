import AppKit
import SwiftUI

@MainActor
final class BatchCaptureTrayController {
    private var panel: NSPanel?

    func show(
        items: [BatchCaptureItem],
        maximumItemCount: Int,
        onContinue: @escaping () -> Void,
        onCopyAll: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRemove: @escaping (UUID) -> Void
    ) {
        let content = BatchCaptureTrayView(
            items: items,
            maximumItemCount: maximumItemCount,
            onContinue: onContinue,
            onCopyAll: onCopyAll,
            onCancel: onCancel,
            onRemove: onRemove
        )
        let frame = trayFrame(itemCount: items.count)
        let hosting = NSHostingView(rootView: content)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        if let panel {
            panel.contentView = hosting
            panel.setFrame(frame, display: true, animate: true)
            panel.orderFrontRegardless()
            return
        }

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hasShadow = true
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

    private func trayFrame(itemCount: Int) -> CGRect {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? .zero
        let thumbnailCount = CGFloat(min(itemCount, 6))
        let width = min(760, max(420, 212 + thumbnailCount * 82))
        let height: CGFloat = 138
        return CGRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.minY + 32,
            width: width,
            height: height
        )
    }
}

private struct BatchCaptureTrayView: View {
    let items: [BatchCaptureItem]
    let maximumItemCount: Int
    let onContinue: () -> Void
    let onCopyAll: () -> Void
    let onCancel: () -> Void
    let onRemove: (UUID) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label("已暂存 \(items.count) 张", systemImage: "photo.stack")
                    .font(.system(size: 13, weight: .semibold))
                Text("最多 \(maximumItemCount) 张")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 86, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        BatchCaptureThumbnail(item: item, onRemove: onRemove)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Button(action: onContinue) {
                    Label("继续", systemImage: "plus")
                }
                .buttonStyle(.bordered)

                Button(action: onCopyAll) {
                    Label("复制全部", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(items.isEmpty)

                Button("取消", action: onCancel)
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .controlSize(.small)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(trayBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var trayBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        shape
            .fill(.regularMaterial)
            .overlay(shape.fill(Color.black.opacity(0.14)))
    }
}

private struct BatchCaptureThumbnail: View {
    let item: BatchCaptureItem
    let onRemove: (UUID) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = NSImage(contentsOf: item.fileURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Color.secondary.opacity(0.2)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            Button {
                onRemove(item.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.62))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
        .frame(width: 76, height: 76)
    }
}
