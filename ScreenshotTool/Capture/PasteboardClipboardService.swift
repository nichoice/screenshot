import AppKit
import CoreGraphics
import Foundation

struct PasteboardClipboardService: ClipboardService {
    func copy(image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: .zero)
        pasteboard.writeObjects([nsImage])
    }

    func copy(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
