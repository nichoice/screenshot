import AppKit
import Foundation

@MainActor
protocol CaptureSoundPlaying {
    func playCaptureSound()
}

protocol CaptureSoundPlayable: AnyObject {
    @discardableResult
    func play() -> Bool
}

extension NSSound: CaptureSoundPlayable {}

@MainActor
final class SystemCaptureSoundPlayer: CaptureSoundPlaying {
    private var activeSound: CaptureSoundPlayable?
    private let soundURLProvider: () -> URL?
    private let soundLoader: (URL) -> CaptureSoundPlayable?

    init(
        soundURLProvider: @escaping () -> URL? = {
            let path = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"
            return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
        },
        soundLoader: @escaping (URL) -> CaptureSoundPlayable? = {
            NSSound(contentsOf: $0, byReference: true)
        }
    ) {
        self.soundURLProvider = soundURLProvider
        self.soundLoader = soundLoader
    }

    func playCaptureSound() {
        guard let soundURL = soundURLProvider(),
              let sound = soundLoader(soundURL) else {
            return
        }

        activeSound = sound
        _ = sound.play()
    }
}
