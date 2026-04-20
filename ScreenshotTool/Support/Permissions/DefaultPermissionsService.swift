import AppKit
import ApplicationServices
import Foundation

struct DefaultPermissionsService: PermissionsService {
    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(
            screenRecording: CGPreflightScreenCaptureAccess() ? .granted : .unknown,
            accessibility: AXIsProcessTrusted() ? .granted : .unknown
        )
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
