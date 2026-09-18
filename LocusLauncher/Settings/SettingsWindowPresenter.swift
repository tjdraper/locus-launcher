import AppKit
import SwiftUI

/// Shows Settings in a plain AppKit window. SwiftUI's `Settings` scene can only be opened from
/// inside a SwiftUI view, and the launcher panel and the app reopen event both come from AppKit.
///
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    private let updates: UpdateController
    private let accessibilityAccess: AccessibilityAccessStore
    private let dockIcon: DockIconPresence
    private let launchAtLogin = LaunchAtLoginStore()
    private let spotlight = SpotlightShortcutStore()
    private lazy var window = makeWindow()

    init(updates: UpdateController, accessibilityAccess: AccessibilityAccessStore, dockIcon: DockIconPresence) {
        self.updates = updates
        self.accessibilityAccess = accessibilityAccess
        self.dockIcon = dockIcon
    }

    func show() {
        dockIcon.windowWillShow(window)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        dockIcon.windowWillClose(window)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: SettingsView(
                updates: updates,
                launchAtLogin: launchAtLogin,
                spotlight: spotlight,
                accessibilityAccess: accessibilityAccess
            )
        ))
        window.title = "Locus Launcher Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}
