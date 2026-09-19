import AppKit
import SwiftUI

/// Shows the setup checklist on a first run, and again whenever the user asks for it.
final class FirstRunWindowPresenter: NSObject, NSWindowDelegate {
    private let updates: UpdateController
    private let launchAtLogin: LaunchAtLoginStore
    private let spotlight: SpotlightShortcutStore
    private let accessibilityAccess: AccessibilityAccessStore
    private let appShortcuts: AppShortcutStore
    private let dockIcon: DockIconPresence
    private lazy var window = makeWindow()

    init(
        updates: UpdateController,
        launchAtLogin: LaunchAtLoginStore,
        spotlight: SpotlightShortcutStore,
        accessibilityAccess: AccessibilityAccessStore,
        appShortcuts: AppShortcutStore,
        dockIcon: DockIconPresence
    ) {
        self.updates = updates
        self.launchAtLogin = launchAtLogin
        self.spotlight = spotlight
        self.accessibilityAccess = accessibilityAccess
        self.appShortcuts = appShortcuts
        self.dockIcon = dockIcon
    }

    func show() {
        updates.defaultToAutomaticChecks()
        dockIcon.windowWillShow(window)
        centerOnPrimaryDisplay()
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    /// Closing the window any way counts as finishing, since the checklist can be reopened. Quitting
    /// with it open doesn't close it, so it opens again on the next launch.
    func windowWillClose(_: Notification) {
        FirstRunStatus().markCompleted()
        dockIcon.windowWillClose(window)
    }

    /// `NSWindow.center()` runs before SwiftUI has sized the window, so it lands off center.
    private func centerOnPrimaryDisplay() {
        guard let screen = NSScreen.screens.first else { return }
        window.layoutIfNeeded()
        let visible = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2))
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: FirstRunView(
                updates: updates,
                launchAtLogin: launchAtLogin,
                spotlight: spotlight,
                accessibilityAccess: accessibilityAccess,
                appShortcuts: appShortcuts,
                onDone: { [weak self] in
                    self?.window.close()
                }
            )
        ))
        window.title = "Set Up Locus Launcher"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}
