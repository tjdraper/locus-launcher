import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    lazy var settings = SettingsWindowPresenter(updates: updates)
    let appIndex = AppIndexStore()
    let appIcons = AppIconCache()
    lazy var launcherPanel = LauncherPanelPresenter(
        settings: settings,
        updates: updates,
        appIndex: appIndex,
        appIcons: appIcons
    )

    func applicationDidFinishLaunching(_: Notification) {
        // A move relaunches the app, so nothing below should start before the offer is settled.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        appIndex.start()
        appIcons.start(observing: appIndex)
        KeyboardShortcuts.onKeyDown(for: .toggleLauncher) { [weak self] in
            self?.launcherPanel.toggle()
        }
        Task {
            await SpotlightConflictLaunchCheck().run()
        }
    }

    /// Opening the app again while it runs is the way back to Settings when the menu bar icon is
    /// hidden.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        settings.show()
        return false
    }
}
