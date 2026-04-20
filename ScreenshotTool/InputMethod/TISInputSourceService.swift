import Carbon
import Foundation

final class TISInputSourceService: InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor] {
        guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return list.compactMap { source in
            guard
                let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                let namePointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
            else {
                return nil
            }

            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
            let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue() as String
            return InputSourceDescriptor(id: id, localizedName: name)
        }
    }

    func currentInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        guard
            let list = TISCreateInputSourceList([kTISPropertyInputSourceID: id] as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource],
            let source = list.first
        else {
            return false
        }

        return TISSelectInputSource(source) == noErr
    }
}
