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
        AppActivation.bringToFront()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_: Notification) {
        dockIcon.windowWillClose(window)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(
            rootView: FirstRunView(
                updates: updates,
                launchAtLogin: launchAtLogin,
                spotlight: spotlight,
                accessibilityAccess: accessibilityAccess,
                appShortcuts: appShortcuts,
                // Only Done finishes the first run. Closing the window or quitting, including the
                // relaunch after moving to Applications, brings the checklist back next launch.
                onDone: { [weak self] in
                    FirstRunStatus().markCompleted()
                    self?.window.close()
                }
            )
        ))
        window.title = "Set Up Locus Launcher"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        RememberedWindowPlacement(autosaveName: "Setup").apply(to: window)
        return window
    }
}
