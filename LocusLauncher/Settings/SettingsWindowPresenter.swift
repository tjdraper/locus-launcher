import AppKit
import SwiftUI

/// Shows Settings in a plain AppKit window. SwiftUI's `Settings` scene can only be opened from
/// inside a SwiftUI view, and the launcher panel and the app reopen event both come from AppKit.
///
/// The app gets a Dock icon while Settings is open, so the window shows up in Cmd+Tab and
/// can be found again after the user switches away.
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    private let updates: UpdateController
    private let launchAtLogin = LaunchAtLoginStore()
    private let spotlight = SpotlightShortcutStore()
    private lazy var window = makeWindow()

    init(updates: UpdateController) {
        self.updates = updates
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: SettingsView(updates: updates, launchAtLogin: launchAtLogin, spotlight: spotlight)
        ))
        window.title = "Locus Launcher Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}
