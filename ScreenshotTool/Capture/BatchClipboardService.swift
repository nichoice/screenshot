import AppKit
import Foundation

protocol BatchClipboardService {
    @discardableResult
    func copy(items: [BatchCaptureItem]) -> Bool
}

struct PasteboardBatchClipboardService: BatchClipboardService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    @discardableResult
    func copy(items: [BatchCaptureItem]) -> Bool {
        let pasteboardItems = items.compactMap { item -> NSPasteboardItem? in
            guard let pngData = try? Data(contentsOf: item.fileURL) else { return nil }

            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setData(pngData, forType: .png)
            pasteboardItem.setString(item.fileURL.absoluteString, forType: .fileURL)
            return pasteboardItem
        }

        guard !pasteboardItems.isEmpty else { return false }
        pasteboard.clearContents()
        return pasteboard.writeObjects(pasteboardItems)
    }
}
