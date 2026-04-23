import AppKit
import ApplicationServices
import Foundation

struct DefaultPermissionsService: PermissionsService {
    private let screenCaptureAccessCheck: () -> Bool
    private let screenCaptureAccessRequest: () -> Bool
    private let accessibilityTrustCheck: () -> Bool

    init(
        screenCaptureAccessCheck: @escaping () -> Bool = { CGPreflightScreenCaptureAccess() },
        screenCaptureAccessRequest: @escaping () -> Bool = { CGRequestScreenCaptureAccess() },
        accessibilityTrustCheck: @escaping () -> Bool = { AXIsProcessTrusted() }
    ) {
        self.screenCaptureAccessCheck = screenCaptureAccessCheck
        self.screenCaptureAccessRequest = screenCaptureAccessRequest
        self.accessibilityTrustCheck = accessibilityTrustCheck
    }

    func currentSnapshot() -> PermissionsSnapshot {
        PermissionsSnapshot(
            screenRecording: screenCaptureAccessCheck() ? .granted : .denied,
            accessibility: accessibilityTrustCheck() ? .granted : .denied
        )
    }

    func requestScreenRecordingAccessIfNeeded() -> Bool {
        if screenCaptureAccessCheck() {
            return true
        }

        return screenCaptureAccessRequest()
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
