import XCTest
@testable import MacShotCore

final class OverlayDoubleClickConfirmationPolicyTests: XCTestCase {
    func testDoubleClickInsideSelectedCaptureRequestsQuickSave() {
        let policy = OverlayDoubleClickConfirmationPolicy(
            clickCount: 2,
            state: .selected,
            currentTool: .arrow,
            isTextEditing: false,
            isRecording: false,
            isScrollCapturing: false,
            isPointInsideSelection: true
        )

        XCTAssertTrue(policy.shouldRequestQuickSave)
    }

    func testSingleClickDoesNotRequestQuickSave() {
        let policy = OverlayDoubleClickConfirmationPolicy(
            clickCount: 1,
            state: .selected,
            currentTool: .arrow,
            isTextEditing: false,
            isRecording: false,
            isScrollCapturing: false,
            isPointInsideSelection: true
        )

        XCTAssertFalse(policy.shouldRequestQuickSave)
    }

    func testDoubleClickDoesNotRequestQuickSaveWhileTextToolIsActive() {
        let policy = OverlayDoubleClickConfirmationPolicy(
            clickCount: 2,
            state: .selected,
            currentTool: .text,
            isTextEditing: false,
            isRecording: false,
            isScrollCapturing: false,
            isPointInsideSelection: true
        )

        XCTAssertFalse(policy.shouldRequestQuickSave)
    }

    func testDoubleClickDoesNotRequestQuickSaveWhileTextEditing() {
        let policy = OverlayDoubleClickConfirmationPolicy(
            clickCount: 2,
            state: .selected,
            currentTool: .arrow,
            isTextEditing: true,
            isRecording: false,
            isScrollCapturing: false,
            isPointInsideSelection: true
        )

        XCTAssertFalse(policy.shouldRequestQuickSave)
    }

    func testDoubleClickDoesNotRequestQuickSaveOutsideSelection() {
        let policy = OverlayDoubleClickConfirmationPolicy(
            clickCount: 2,
            state: .selected,
            currentTool: .arrow,
            isTextEditing: false,
            isRecording: false,
            isScrollCapturing: false,
            isPointInsideSelection: false
        )

        XCTAssertFalse(policy.shouldRequestQuickSave)
    }
}
