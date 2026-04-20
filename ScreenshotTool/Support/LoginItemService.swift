import Foundation

protocol LoginItemService {
    func currentStatus() -> Bool
    func setLaunchAtLogin(_ enabled: Bool) throws
}
