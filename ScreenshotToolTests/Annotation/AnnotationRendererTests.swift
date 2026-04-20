import CoreGraphics
import XCTest
@testable import ScreenshotTool

final class AnnotationRendererTests: XCTestCase {
    func testRenderChangesImageWhenRectangleAnnotationExists() {
        let baseImage = makeSolidImage(width: 20, height: 20, rgba: (255, 255, 255, 255))
        let renderer = AnnotationRenderer()

        let rendered = renderer.render(
            baseImage: baseImage,
            items: [.rectangle(CGRect(x: 2, y: 2, width: 12, height: 12), "#FF0000", 2)]
        )

        XCTAssertNotEqual(pixelData(baseImage), pixelData(rendered))
    }
}

private func makeSolidImage(width: Int, height: Int, rgba: (UInt8, UInt8, UInt8, UInt8)) -> CGImage {
    var bytes = [UInt8]()
    bytes.reserveCapacity(width * height * 4)

    for _ in 0..<(width * height) {
        bytes.append(rgba.0)
        bytes.append(rgba.1)
        bytes.append(rgba.2)
        bytes.append(rgba.3)
    }

    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)),
        provider: CGDataProvider(data: Data(bytes) as CFData)!,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}

private func pixelData(_ image: CGImage) -> Data {
    guard let provider = image.dataProvider, let data = provider.data else {
        return Data()
    }

    return data as Data
}
