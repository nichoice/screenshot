import AppKit
import XCTest
@testable import MacShotCore

final class MacShotToolbarPolicyTests: XCTestCase {
    func testPhaseOneBottomToolbarDoesNotExposeUnsupportedActions() {
        let actions = ToolbarLayout.bottomButtons(
            selectedTool: .arrow,
            selectedColor: .systemRed,
            hasAnnotations: false
        ).map(\.action)

        XCTAssertFalse(actions.containsAction(.effects))
        XCTAssertFalse(actions.containsAction(.beautify))
    }

    func testRightToolbarExposesRecordActionOutsideEditorMode() {
        let actions = ToolbarLayout.rightButtons(isEditorMode: false).map(\.action)

        XCTAssertTrue(actions.containsAction(.record))
    }

    func testRightToolbarAlwaysExposesRecordActionWhenSavedActionPreferencesOmitRecordingTag() {
        let defaults = UserDefaults.standard
        let previousEnabledActions = defaults.object(forKey: "enabledActions")
        let previousKnownActionTags = defaults.object(forKey: "knownActionTags")
        defaults.set([1001, 1002, 1003], forKey: "enabledActions")
        defaults.set([1001, 1002, 1003, 1009], forKey: "knownActionTags")
        defer {
            restore(previousEnabledActions, forKey: "enabledActions", defaults: defaults)
            restore(previousKnownActionTags, forKey: "knownActionTags", defaults: defaults)
        }

        let actions = ToolbarLayout.rightButtons(isEditorMode: false).map(\.action)

        XCTAssertTrue(actions.containsAction(.record))
    }

    func testRightToolbarHidesRecordActionInEditorMode() {
        let actions = ToolbarLayout.rightButtons(isEditorMode: true).map(\.action)

        XCTAssertFalse(actions.containsAction(.record))
    }

    func testRecordingSetupToolbarHidesUnsupportedMVPRecordingOptions() {
        let actions = ToolbarLayout.rightButtons(isRecording: true).map(\.action)

        XCTAssertTrue(actions.containsAction(.startRecord))
        XCTAssertTrue(actions.containsAction(.stopRecord))
        XCTAssertTrue(actions.containsAction(.moveSelection))
        XCTAssertFalse(actions.containsAction(.mouseHighlight))
        XCTAssertFalse(actions.containsAction(.showKeystrokes))
        XCTAssertFalse(actions.containsAction(.systemAudio))
        XCTAssertFalse(actions.containsAction(.micAudio))
        XCTAssertFalse(actions.containsAction(.webcam))
        XCTAssertFalse(actions.containsAction(.recordSettings))
    }

    func testPhaseOneRightToolbarDoesNotExposeUnsupportedActions() {
        let actions = ToolbarLayout.rightButtons().map(\.action)

        XCTAssertFalse(actions.containsAction(.scrollCapture))
        XCTAssertFalse(actions.containsAction(.upload))
        XCTAssertFalse(actions.containsAction(.ocr))
        XCTAssertFalse(actions.containsAction(.translate))
    }
}

private extension [ToolbarButtonAction] {
    func containsAction(_ expected: ToolbarButtonAction) -> Bool {
        contains { action in
            switch (action, expected) {
            case (.effects, .effects),
                 (.beautify, .beautify),
                 (.record, .record),
                 (.startRecord, .startRecord),
                 (.stopRecord, .stopRecord),
                 (.moveSelection, .moveSelection),
                 (.mouseHighlight, .mouseHighlight),
                 (.showKeystrokes, .showKeystrokes),
                 (.systemAudio, .systemAudio),
                 (.micAudio, .micAudio),
                 (.webcam, .webcam),
                 (.recordSettings, .recordSettings),
                 (.scrollCapture, .scrollCapture),
                 (.upload, .upload),
                 (.ocr, .ocr),
                 (.translate, .translate):
                true
            default:
                false
            }
        }
    }
}

private func restore(_ value: Any?, forKey key: String, defaults: UserDefaults) {
    if let value {
        defaults.set(value, forKey: key)
    } else {
        defaults.removeObject(forKey: key)
    }
}
