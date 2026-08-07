import AppKit
import CoreGraphics
import Foundation

struct PasteboardClipboardService: ClipboardService {
    func copy(image: CGImage) {
        guard let data = CaptureImageDataEncoder.encodePNG(image) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.png], owner: nil)
        pasteboard.setData(data, forType: .png)
    }

    func copy(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
