import AppKit
import SwiftUI

/// Shows Settings in a plain AppKit window. SwiftUI's `Settings` scene can only be opened from
/// inside a SwiftUI view, and the launcher panel and the app reopen event both come from AppKit.
///
/// The app gets a Dock icon while Settings is open, so the window shows up in Cmd+Tab and
/// can be found again after the user switches away.
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    private lazy var window = makeWindow()

    func show() {
        NSApp.setActivationPolicy(.regular)
        activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// `NSApp.activate()` is only a request, and macOS turns it down while another app is in
    /// front, which is always the case when Settings is opened from the menu bar or the
    /// launcher panel. Asking on behalf of the frontmost app is honored.
    private func activate() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            NSApp.activate()
            return
        }
        NSRunningApplication.current.activate(from: frontmost, options: [])
    }

    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = "Locus Launcher Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}
