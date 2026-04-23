import Foundation

enum PermissionState: Equatable {
    case unknown
    case granted
    case denied

    var displayName: String {
        switch self {
        case .unknown:
            "未知"
        case .granted:
            "已授权"
        case .denied:
            "未授权"
        }
    }
}

struct PermissionsSnapshot: Equatable {
    var screenRecording: PermissionState
    var accessibility: PermissionState
}

protocol PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot
    func requestScreenRecordingAccessIfNeeded() -> Bool
    func openScreenRecordingSettings()
    func openAccessibilitySettings()
}
