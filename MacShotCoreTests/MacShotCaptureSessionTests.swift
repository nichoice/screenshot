import XCTest
import AppKit
@testable import MacShotCore

@MainActor
final class MacShotCaptureSessionTests: XCTestCase {
    func testSessionStartsOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)

        XCTAssertTrue(session.start())
        XCTAssertFalse(session.start())
        XCTAssertEqual(session.state, .running)
    }

    func testCancelMovesSessionToCancelledOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)
        _ = session.start()

        XCTAssertTrue(session.cancel())
        XCTAssertFalse(session.cancel())
        XCTAssertEqual(session.state, .cancelled)
    }

    func testSessionCompletesOnlyOnce() {
        let session = MacShotCaptureSession(preferences: .defaults, presentsOverlay: false)
        _ = session.start()
        let image = NSImage(size: NSSize(width: 10, height: 8))

        XCTAssertTrue(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 456)))
        XCTAssertFalse(session.complete(with: image, capturedAt: Date(timeIntervalSince1970: 789)))
        XCTAssertEqual(session.state, .completed)
    }

    func testSessionDismissesOverlaysBeforeCompletionHandler() {
        var didDismissOverlays = false
        var completionObservedDismissedOverlays = false
        let session = MacShotCaptureSession(
            preferences: .defaults,
            presentsOverlay: false,
            onComplete: { _ in
                completionObservedDismissedOverlays = didDismissOverlays
            },
            onDismissOverlays: {
                didDismissOverlays = true
            }
        )
        _ = session.start()
        let image = NSImage(size: NSSize(width: 10, height: 8))

        XCTAssertTrue(session.complete(with: image))
        XCTAssertTrue(didDismissOverlays)
        XCTAssertTrue(completionObservedDismissedOverlays)
    }

    func testEngineStoresCompletionHandlerUntilSessionCompletes() {
        let engine = MacShotCaptureEngine(presentsOverlay: false)
        var received: MacShotCaptureResult?

        XCTAssertTrue(engine.startCapture(preferences: .defaults) { result in
            received = result
        } onCancel: {})

        let image = NSImage(size: NSSize(width: 10, height: 8))
        engine.completeForTesting(image: image, capturedAt: Date(timeIntervalSince1970: 321))

        XCTAssertEqual(received?.capturedAt, Date(timeIntervalSince1970: 321))
        XCTAssertFalse(engine.isCapturing)
    }

    func testShareableContentCacheCoalescesConcurrentLoads() async throws {
        var loadCount = 0
        let cache = ShareableContentCache<Int> {
            loadCount += 1
            try await Task.sleep(nanoseconds: 20_000_000)
            return 42
        }

        async let first = cache.value()
        async let second = cache.value()
        let (firstValue, secondValue) = try await (first, second)

        XCTAssertEqual(firstValue, 42)
        XCTAssertEqual(secondValue, 42)
        XCTAssertEqual(loadCount, 1)
    }

    func testShareableContentCacheReloadsOnlyAfterInvalidation() async throws {
        var loadCount = 0
        let cache = ShareableContentCache<Int> {
            loadCount += 1
            return loadCount
        }

        let firstValue = try await cache.value()
        let cachedValue = try await cache.value()
        cache.invalidate()
        let reloadedValue = try await cache.value()

        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(cachedValue, 1)
        XCTAssertEqual(reloadedValue, 2)
    }

    func testShareableContentCacheCanAdoptFreshFallbackValue() async throws {
        var loadCount = 0
        let cache = ShareableContentCache<Int> {
            loadCount += 1
            return 1
        }

        let initialValue = try await cache.value()
        cache.replace(with: 7)
        let replacedValue = try await cache.value()

        XCTAssertEqual(initialValue, 1)
        XCTAssertEqual(replacedValue, 7)
        XCTAssertEqual(loadCount, 1)
    }

    func testCaptureExclusionPrefersCurrentApplicationOverFreshWindowEnumeration() {
        XCTAssertEqual(
            ScreenCaptureExclusionStrategy.resolve(
                currentApplicationAvailable: true,
                excludedWindowCount: 2
            ),
            .currentApplication
        )
        XCTAssertEqual(
            ScreenCaptureExclusionStrategy.resolve(
                currentApplicationAvailable: false,
                excludedWindowCount: 2
            ),
            .freshWindows
        )
        XCTAssertEqual(
            ScreenCaptureExclusionStrategy.resolve(
                currentApplicationAvailable: false,
                excludedWindowCount: 0
            ),
            .cachedWindows
        )
    }

    func testEnginePrepareForCaptureInvokesPrewarmAction() {
        var prepareCount = 0
        let engine = MacShotCaptureEngine(
            presentsOverlay: false,
            prewarmAction: { prepareCount += 1 }
        )

        engine.prepareForCapture()

        XCTAssertEqual(prepareCount, 1)
    }
}
