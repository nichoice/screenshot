import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureCoordinatorTests: XCTestCase {
    @MainActor
    func testCompleteSelectionCapturesImageAndPublishesResult() async throws {
        let service = FakeScreenCaptureService()
        let coordinator = CaptureCoordinator(
            screenCaptureService: service,
            desktopRectProvider: { CGRect(x: 0, y: 0, width: 200, height: 100) }
        )
        coordinator.beginCapture()
        coordinator.updateSelection(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 110, y: 60))

        try await coordinator.completeSelection()

        XCTAssertEqual(service.capturedRects, [.infinite])
        XCTAssertEqual(coordinator.lastResult?.selectionRect, CGRect(x: 10, y: 10, width: 100, height: 50))
        XCTAssertNotNil(coordinator.lastResult?.fullImage)
        XCTAssertFalse(coordinator.isCapturing)
    }

    @MainActor
    func testBeginCaptureIgnoresDuplicateStartWhileAlreadyCapturing() {
        let service = FakeScreenCaptureService()
        let coordinator = CaptureCoordinator(
            screenCaptureService: service,
            desktopRectProvider: { CGRect(x: 0, y: 0, width: 200, height: 100) }
        )
        var startCount = 0
        coordinator.onCaptureStarted = {
            startCount += 1
        }

        coordinator.beginCapture()
        coordinator.beginCapture()

        XCTAssertEqual(startCount, 1)
        XCTAssertTrue(coordinator.isCapturing)
    }

    @MainActor
    func testCompleteSelectionResetsStateWhenCaptureFails() async {
        let coordinator = CaptureCoordinator(
            screenCaptureService: FailingScreenCaptureService(),
            desktopRectProvider: { CGRect(x: 0, y: 0, width: 200, height: 100) }
        )
        coordinator.beginCapture()
        coordinator.updateSelection(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 110, y: 60))

        do {
            try await coordinator.completeSelection()
            XCTFail("Expected capture to fail")
        } catch {
            XCTAssertFalse(coordinator.isCapturing)
            XCTAssertNil(coordinator.currentSelection)
            XCTAssertNil(coordinator.lastResult)
        }
    }

    @MainActor
    func testCompleteSelectionCancelsCaptureWhenNoSelectionExists() async throws {
        let service = FakeScreenCaptureService()
        let coordinator = CaptureCoordinator(
            screenCaptureService: service,
            desktopRectProvider: { CGRect(x: 0, y: 0, width: 200, height: 100) }
        )
        var didCancel = false
        coordinator.onCaptureCancelled = {
            didCancel = true
        }
        coordinator.beginCapture()

        try await coordinator.completeSelection()

        XCTAssertTrue(didCancel)
        XCTAssertFalse(coordinator.isCapturing)
        XCTAssertTrue(service.capturedRects.isEmpty)
    }
}

private final class FakeScreenCaptureService: ScreenCaptureService, @unchecked Sendable {
    var capturedRects: [CGRect] = []

    func capture(rect: CGRect) throws -> CGImage {
        capturedRects.append(rect)
        return CGImage(
            width: 200,
            height: 100,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 200 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
            provider: CGDataProvider(data: Data(repeating: 255, count: 200 * 100 * 4) as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}

private struct FailingScreenCaptureService: ScreenCaptureService {
    struct ExpectedFailure: Error {}

    func capture(rect: CGRect) throws -> CGImage {
        throw ExpectedFailure()
    }
}
