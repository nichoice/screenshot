import Foundation

enum CaptureOverlayBorderStyle: Equatable {
    case light
    case dark
}

enum CaptureOverlayContrast {
    static func borderStyle(forBackgroundLuminance luminance: Double) -> CaptureOverlayBorderStyle {
        luminance < 0.5 ? .light : .dark
    }
}
