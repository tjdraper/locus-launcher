import AppKit
import ApplicationServices

/// Whether the app may send keystrokes to other apps, which New Window needs to press Cmd+N. The
/// user grants it in System Settings, which doesn't announce changes, so callers refresh when the
/// app comes forward.
@Observable
final class AccessibilityAccessStore {
    /// macOS only shows its prompt the first time an app asks, so after that the app opens the
    /// System Settings page instead.
    private static let askedDefaultsKey = "AskedForAccessibilityAccess"

    private(set) var isGranted = AXIsProcessTrusted()

    func refresh() {
        isGranted = AXIsProcessTrusted()
    }

    func requestAccess() {
        guard !UserDefaults.standard.bool(forKey: Self.askedDefaultsKey) else {
            openAccessibilitySettings()
            return
        }
        UserDefaults.standard.set(true, forKey: Self.askedDefaultsKey)
        // The literal stands in for `kAXTrustedCheckOptionPrompt`, a global var that Swift 6
        // rejects as not concurrency-safe.
        isGranted = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    /// Asks once, the first time an action needs access, and stays quiet after that.
    func requestAccessIfNeverAsked() {
        guard !UserDefaults.standard.bool(forKey: Self.askedDefaultsKey) else { return }
        requestAccess()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
