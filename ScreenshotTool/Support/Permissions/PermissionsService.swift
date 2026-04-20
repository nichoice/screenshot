import Foundation

enum PermissionState: Equatable {
    case unknown
    case granted
    case denied
}

struct PermissionsSnapshot: Equatable {
    var screenRecording: PermissionState
    var accessibility: PermissionState
}

protocol PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot
    func openScreenRecordingSettings()
    func openAccessibilitySettings()
}
