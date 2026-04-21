import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class CaptureImageCropperTests: XCTestCase {
    func testCropUsesBottomLeftSelectionCoordinates() {
        let image = makeQuadrantImage()

        let cropped = CaptureImageCropper.crop(
            image: image,
            imageBounds: CGRect(x: 0, y: 0, width: 4, height: 4),
            selectionRect: CGRect(x: 0, y: 0, width: 2, height: 2)
        )

        let pixel = samplePixel(cropped, x: 0, y: 0)
        XCTAssertEqual(pixel?.0, 255)
        XCTAssertEqual(pixel?.1, 0)
        XCTAssertEqual(pixel?.2, 0)
        XCTAssertEqual(pixel?.3, 255)
    }
}

private func makeQuadrantImage() -> CGImage {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(4 * 4 * 4)

    for y in 0..<4 {
        for x in 0..<4 {
            let rgba: (UInt8, UInt8, UInt8, UInt8)
            switch (x < 2, y < 2) {
            case (true, true):
                rgba = (0, 0, 255, 255) // top-left
            case (false, true):
                rgba = (255, 255, 0, 255) // top-right
            case (true, false):
                rgba = (255, 0, 0, 255) // bottom-left
            case (false, false):
                rgba = (0, 255, 0, 255) // bottom-right
            }
            bytes.append(contentsOf: [rgba.0, rgba.1, rgba.2, rgba.3])
        }
    }

    return CGImage(
        width: 4,
        height: 4,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: 16,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: CGDataProvider(data: Data(bytes) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}

private func samplePixel(_ image: CGImage?, x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8)? {
    guard
        let image,
        let data = image.dataProvider?.data
    else {
        return nil
    }

    let bytes = CFDataGetBytePtr(data)!
    let offset = y * image.bytesPerRow + x * 4
    return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
}
