import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class AnnotationEditorStateTests: XCTestCase {
    @MainActor
    func testCommitDragCreatesRectangleAnnotationForRectangleTool() {
        let document = AnnotationDocument()
        let state = AnnotationEditorState(document: document)
        state.selectedTool = .rectangle
        state.strokeColorHex = "#00FF00"
        state.lineWidth = 3

        state.commitDrag(from: CGPoint(x: 30, y: 40), to: CGPoint(x: 10, y: 20))

        XCTAssertEqual(document.items, [
            .rectangle(CGRect(x: 10, y: 20, width: 20, height: 20), "#00FF00", 3)
        ])
    }

    @MainActor
    func testCommitTextCreatesTextAnnotationAtPoint() {
        let document = AnnotationDocument()
        let state = AnnotationEditorState(document: document)
        state.selectedTool = .text
        state.strokeColorHex = "#111111"
        state.fontSize = 18
        state.textValue = "hello"

        state.commitClick(at: CGPoint(x: 5, y: 8))

        XCTAssertEqual(document.items, [
            .text("hello", CGPoint(x: 5, y: 8), "#111111", 18)
        ])
    }

    @MainActor
    func testCommitDragCreatesEllipseAnnotationForEllipseTool() {
        let document = AnnotationDocument()
        let state = AnnotationEditorState(document: document)
        state.selectedTool = .ellipse
        state.strokeColorHex = "#123456"
        state.lineWidth = 5

        state.commitDrag(from: CGPoint(x: 12, y: 18), to: CGPoint(x: 42, y: 54))

        XCTAssertEqual(document.items, [
            .ellipse(CGRect(x: 12, y: 18, width: 30, height: 36), "#123456", 5)
        ])
    }

    @MainActor
    func testCommitPenCreatesPenAnnotation() {
        let document = AnnotationDocument()
        let state = AnnotationEditorState(document: document)
        state.selectedTool = .pen
        state.strokeColorHex = "#FF0000"
        state.lineWidth = 2

        state.commitPath([CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2), CGPoint(x: 3, y: 4)])

        XCTAssertEqual(document.items, [
            .pen([CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2), CGPoint(x: 3, y: 4)], "#FF0000", 2)
        ])
    }
}
