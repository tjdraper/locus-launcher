import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsWindowPresenter()
    let appIndex = AppIndexStore()
    lazy var launcherPanel = LauncherPanelPresenter(settings: settings, appIndex: appIndex)
    let updates = UpdateController()

    func applicationDidFinishLaunching(_: Notification) {
        // A move relaunches the app, so nothing below should start before the offer is settled.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        appIndex.start()
        KeyboardShortcuts.onKeyDown(for: .toggleLauncher) { [weak self] in
            self?.launcherPanel.toggle()
        }
    }

    /// Opening the app again while it runs is the way back to Settings when the menu bar icon is
    /// hidden.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        settings.show()
        return false
    }
}
