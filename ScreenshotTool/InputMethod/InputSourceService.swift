import Foundation

protocol InputSourceService {
    func availableInputSources() -> [InputSourceDescriptor]
    func currentInputSourceID() -> String?
    @discardableResult
    func selectInputSource(id: String) -> Bool
}
