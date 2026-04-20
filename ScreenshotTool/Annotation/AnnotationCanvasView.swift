import AppKit
import SwiftUI

struct AnnotationCanvasView: NSViewRepresentable {
    let image: CGImage
    @ObservedObject var document: AnnotationDocument

    func makeNSView(context: Context) -> NSImageView {
        NSImageView(image: NSImage(cgImage: image, size: .zero))
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(cgImage: image, size: .zero)
    }
}
