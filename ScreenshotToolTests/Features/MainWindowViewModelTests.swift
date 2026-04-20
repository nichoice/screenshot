import XCTest
@testable import ScreenshotTool

final class MainWindowViewModelTests: XCTestCase {
    @MainActor
    func testRefreshPullsLatestHistoryItems() throws {
        let permissionsService = LocalFakePermissionsService()
        let router = WindowRouter()
        let historyURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(#function).json")
        try? FileManager.default.removeItem(at: historyURL)
        let historyStore = CaptureHistoryStore(fileURL: historyURL, limit: 5)
        try historyStore.append(CaptureHistoryItem(id: UUID(), createdAt: Date(), previewFilePath: "preview.png", savedFilePath: nil, didCopyToClipboard: true))

        let viewModel = MainWindowViewModel(
            permissionsService: permissionsService,
            windowRouter: router,
            historyStore: historyStore
        )

        viewModel.refresh()

        XCTAssertEqual(viewModel.recentCaptures.count, 1)
    }
}

private struct LocalFakePermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(screenRecording: .unknown, accessibility: .unknown)
    }

    func openScreenRecordingSettings() {}
    func openAccessibilitySettings() {}
}
