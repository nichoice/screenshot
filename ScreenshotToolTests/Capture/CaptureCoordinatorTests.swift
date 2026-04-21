import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureCoordinatorTests: XCTestCase {
    @MainActor
    func testCompleteSelectionCapturesImageAndPublishesResult() async throws {
        let service = FakeScreenCaptureService()
        let coordinator = CaptureCoordinator(screenCaptureService: service)
        coordinator.beginCapture()
        coordinator.updateSelection(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 110, y: 60))

        try await coordinator.completeSelection()

        XCTAssertEqual(service.capturedRects, [CGRect(x: 10, y: 10, width: 100, height: 50), .infinite])
        XCTAssertEqual(coordinator.lastResult?.selectionRect, CGRect(x: 10, y: 10, width: 100, height: 50))
        XCTAssertNotNil(coordinator.lastResult?.fullImage)
        XCTAssertFalse(coordinator.isCapturing)
    }
}

private final class FakeScreenCaptureService: ScreenCaptureService {
    var capturedRects: [CGRect] = []

    func capture(rect: CGRect) throws -> CGImage {
        capturedRects.append(rect)
        return CGImage(
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
            provider: CGDataProvider(data: Data(repeating: 255, count: 16) as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}
