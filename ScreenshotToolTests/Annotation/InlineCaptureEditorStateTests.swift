import Combine
import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class InlineCaptureEditorStateTests: XCTestCase {
    @MainActor
    func testResizeSelectionTrailingHandleExpandsWidth() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 100, height: 80),
                image: makeImage(width: 40, height: 30),
                selectionRect: CGRect(x: 10, y: 10, width: 40, height: 30),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 100, height: 80),
            document: AnnotationDocument()
        )

        let initial = state.selectionRect
        state.resizeSelection(using: .trailing, translation: CGSize(width: 20, height: 0), initialRect: initial)

        XCTAssertEqual(state.selectionRect.width, 60)
    }

    @MainActor
    func testMoveSelectionOffsetsRectWithinAvailableBounds() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.moveSelection(translation: CGSize(width: 30, height: 20), initialRect: state.selectionRect)

        XCTAssertEqual(state.selectionRect.origin.x, 80)
        XCTAssertEqual(state.selectionRect.origin.y, 60)
        XCTAssertEqual(state.selectionRect.size.width, 100)
        XCTAssertEqual(state.selectionRect.size.height, 80)
    }

    @MainActor
    func testMoveSelectionClampsRectInsideAvailableBounds() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 220, y: 130, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.moveSelection(translation: CGSize(width: 60, height: 50), initialRect: state.selectionRect)

        XCTAssertEqual(state.selectionRect.maxX, 300)
        XCTAssertEqual(state.selectionRect.maxY, 200)
    }

    @MainActor
    func testActivatingToolLeavesSelectionModeAndRetappingSameToolRestoresSelectionMode() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        XCTAssertTrue(state.isSelectionModeActive)

        state.activateTool(.arrow)
        XCTAssertFalse(state.isSelectionModeActive)
        XCTAssertEqual(state.editorState.selectedTool, .arrow)

        state.activateTool(.arrow)
        XCTAssertTrue(state.isSelectionModeActive)
    }

    @MainActor
    func testBeginTextEntryCreatesDraftAtLocalPoint() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.activateTool(.text)
        state.beginTextEntry(atLocalPoint: CGPoint(x: 12, y: 24))

        XCTAssertEqual(state.textDraft?.text, "")
        XCTAssertEqual(state.textDraft?.globalPoint, CGPoint(x: 62, y: 64))
    }

    @MainActor
    func testCommitTextDraftAddsAnnotationAndClearsDraft() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.activateTool(.text)
        state.beginTextEntry(atLocalPoint: CGPoint(x: 12, y: 24))
        state.textDraft?.text = "hello"

        state.commitTextEntry()

        XCTAssertNil(state.textDraft)
        XCTAssertEqual(state.document.items, [
            .text("hello", CGPoint(x: 62, y: 64), "#FF3B30", 16)
        ])
    }

    @MainActor
    func testDocumentMutationsPublishAfterUpdatedAnnotationItemsAreAvailable() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )
        let expectation = expectation(description: "state publishes updated annotation items")
        var observedCounts: [Int] = []
        let cancellable = state.objectWillChange.sink {
            observedCounts.append(state.localAnnotationItems.count)
            expectation.fulfill()
        }

        state.document.add(.rectangle(CGRect(x: 55, y: 45, width: 30, height: 20), "#FF3B30", 4))

        wait(for: [expectation], timeout: 1)
        withExtendedLifetime(cancellable) {}
        XCTAssertEqual(observedCounts, [1])
    }

    @MainActor
    func testCommitEmptyTextDraftCancelsWithoutAddingAnnotation() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.activateTool(.text)
        state.beginTextEntry(atLocalPoint: CGPoint(x: 12, y: 24))

        state.commitTextEntry()

        XCTAssertNil(state.textDraft)
        XCTAssertTrue(state.document.items.isEmpty)
    }

    @MainActor
    func testInsertEmojiAddsTextAnnotationAtSelectionCenter() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.insertEmoji("🙂")

        XCTAssertEqual(state.document.items, [
            .text("🙂", CGPoint(x: 100, y: 80), "#FF3B30", 24)
        ])
    }

    @MainActor
    func testLocalPointToGlobalIncludesScreenOrigin() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 500, height: 320),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 460, y: 170, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 400, y: 120, width: 700, height: 520),
            document: AnnotationDocument()
        )

        let globalPoint = state.localPointToGlobal(CGPoint(x: 12, y: 18))

        XCTAssertEqual(globalPoint, CGPoint(x: 472, y: 188))
    }

    @MainActor
    func testDisplaySelectionRectConvertsAppKitSelectionIntoOnScreenEditorPosition() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        XCTAssertEqual(state.displaySelectionRect, CGRect(x: 50, y: 80, width: 100, height: 80))
    }

    @MainActor
    func testDisplayTextDraftCanvasPointTracksClickedTextLocationInEditorCoordinates() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.activateTool(.text)
        state.beginTextEntry(atLocalPoint: CGPoint(x: 12, y: 24))

        XCTAssertEqual(state.displayTextDraftCanvasPoint, CGPoint(x: 12, y: 56))
    }

    @MainActor
    func testMoveDisplaySelectionUpdatesGlobalSelectionRectWithoutLosingOriginalPlacement() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 500, height: 320),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 460, y: 170, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 400, y: 120, width: 700, height: 520),
            document: AnnotationDocument()
        )

        state.moveDisplaySelection(
            translation: CGSize(width: 20, height: 30),
            initialRect: state.displaySelectionRect
        )

        XCTAssertEqual(state.displaySelectionRect, CGRect(x: 80, y: 420, width: 100, height: 80))
        XCTAssertEqual(state.globalSelectionRect, CGRect(x: 480, y: 140, width: 100, height: 80))
    }

    @MainActor
    func testLocalAnnotationItemsUseGlobalSelectionOrigin() {
        let document = AnnotationDocument()
        document.add(.text("Pinned", CGPoint(x: 470, y: 190), "#FF3B30", 16))
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 500, height: 320),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 460, y: 170, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 400, y: 120, width: 700, height: 520),
            document: document
        )

        XCTAssertEqual(state.localAnnotationItems, [
            .text("Pinned", CGPoint(x: 10, y: 20), "#FF3B30", 16)
        ])
    }

    @MainActor
    func testPresentOCRResultStoresRecognizedTextAndFeedbackMessage() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.presentRecognizedText("第一行\n第二行")

        XCTAssertEqual(state.lastRecognizedText, "第一行\n第二行")
        XCTAssertEqual(state.feedbackBanner?.message, "已复制 2 行文字")
    }

    @MainActor
    func testFeedbackBannerIDChangesWhenShowingReplacementMessage() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.showFeedback("已复制")
        let firstID = state.feedbackBanner?.id
        state.showFeedback("已保存")

        XCTAssertNotNil(firstID)
        XCTAssertNotEqual(firstID, state.feedbackBanner?.id)
        XCTAssertEqual(state.feedbackBanner?.message, "已保存")
    }

    @MainActor
    func testDismissFeedbackBannerOnlyClearsMatchingID() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        state.showFeedback("已复制")
        let staleID = state.feedbackBanner?.id
        state.showFeedback("已保存")

        state.dismissFeedbackBanner(id: staleID!)

        XCTAssertEqual(state.feedbackBanner?.message, "已保存")
    }

    @MainActor
    func testBeginBusyActionTracksToolbarItemUntilMatchingTokenEnds() {
        let state = InlineCaptureEditorState(
            result: CaptureResult(
                fullImage: makeImage(width: 300, height: 200),
                image: makeImage(width: 100, height: 80),
                selectionRect: CGRect(x: 50, y: 40, width: 100, height: 80),
                capturedAt: Date()
            ),
            screenFrame: CGRect(x: 0, y: 0, width: 300, height: 200),
            document: AnnotationDocument()
        )

        let staleToken = state.beginBusyAction(.ocr)
        let currentToken = state.beginBusyAction(.ocr)

        XCTAssertTrue(state.isBusy(.ocr))

        state.endBusyAction(.ocr, token: staleToken)
        XCTAssertTrue(state.isBusy(.ocr))

        state.endBusyAction(.ocr, token: currentToken)
        XCTAssertFalse(state.isBusy(.ocr))
    }
}

private func makeImage(width: Int, height: Int) -> CGImage {
    CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: CGDataProvider(data: Data(repeating: 255, count: width * height * 4) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
