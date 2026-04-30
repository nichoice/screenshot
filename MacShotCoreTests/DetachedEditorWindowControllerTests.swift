import AppKit
import XCTest
@testable import MacShotCore

@MainActor
final class DetachedEditorWindowControllerTests: XCTestCase {
    override func tearDown() {
        DetachedEditorWindowController.backgroundRemover = VisionBackgroundRemover()
        super.tearDown()
    }

    func testOpenCreatesEditorWindowContainingEditorView() throws {
        let app = NSApplication.shared
        let existingWindows = Set(app.windows.map(ObjectIdentifier.init))
        let image = Self.makeTestImage()

        DetachedEditorWindowController.open(image: image)

        let window = try XCTUnwrap(app.windows.first { window in
            !existingWindows.contains(ObjectIdentifier(window)) && window.title.contains("Editor")
        })
        XCTAssertTrue(Self.containsEditorView(in: window.contentView))

        window.close()
    }

    func testRemoveBackgroundReplacesEditorImageAndClearsAnnotations() async throws {
        let app = NSApplication.shared
        let existingWindows = Set(app.windows.map(ObjectIdentifier.init))
        let originalImage = Self.makeTestImage()
        let replacementImage = Self.makeReplacementImage()
        let remover = StubBackgroundRemover(replacement: replacementImage)
        DetachedEditorWindowController.backgroundRemover = remover

        let annotation = Annotation(
            tool: .rectangle,
            startPoint: NSPoint(x: 10, y: 10),
            endPoint: NSPoint(x: 40, y: 40),
            color: .systemBlue,
            strokeWidth: 2
        )
        DetachedEditorWindowController.open(image: originalImage, annotations: [annotation])

        let window = try XCTUnwrap(app.windows.first { window in
            !existingWindows.contains(ObjectIdentifier(window)) && window.title.contains("Editor")
        })
        let editorView = try XCTUnwrap(Self.editorView(in: window.contentView))
        let originalUndoCount = editorView.undoStack.count

        editorView.handleToolbarAction(.removeBackground)
        for _ in 0..<20 where remover.inputImage == nil || !editorView.annotations.isEmpty {
            await Task.yield()
        }

        XCTAssertEqual(remover.inputImage?.size, originalImage.size)
        XCTAssertEqual(editorView.screenshotImage?.size, replacementImage.size)
        XCTAssertTrue(editorView.annotations.isEmpty)
        XCTAssertEqual(editorView.undoStack.count, originalUndoCount + 1)
        XCTAssertTrue(editorView.redoStack.isEmpty)

        window.close()
    }

    private static func makeTestImage() -> NSImage {
        let size = NSSize(width: 160, height: 90)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        NSColor.systemRed.setFill()
        NSBezierPath(rect: NSRect(x: 20, y: 20, width: 80, height: 36)).fill()
        image.unlockFocus()
        return image
    }

    private static func makeReplacementImage() -> NSImage {
        let size = NSSize(width: 160, height: 90)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        NSColor.systemGreen.setFill()
        NSBezierPath(ovalIn: NSRect(x: 44, y: 18, width: 72, height: 54)).fill()
        image.unlockFocus()
        return image
    }

    private static func containsEditorView(in view: NSView?) -> Bool {
        editorView(in: view) != nil
    }

    private static func editorView(in view: NSView?) -> EditorView? {
        guard let view else { return nil }
        if let editorView = view as? EditorView { return editorView }
        for subview in view.subviews {
            if let editorView = editorView(in: subview) {
                return editorView
            }
        }
        return nil
    }
}

private final class StubBackgroundRemover: BackgroundRemoving {
    let replacement: NSImage
    var inputImage: NSImage?

    init(replacement: NSImage) {
        self.replacement = replacement
    }

    func removeBackground(from image: NSImage) async throws -> NSImage {
        inputImage = image
        return replacement
    }
}
