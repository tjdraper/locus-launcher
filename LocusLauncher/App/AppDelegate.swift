import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updates = UpdateController()
    let appIndex = AppIndexStore()
    let appIcons = AppIconCache()
    let hiddenApps = HiddenAppsStore()
    let appShortcuts = AppShortcutStore()
    let accessibilityAccess = AccessibilityAccessStore()
    let launchAtLogin = LaunchAtLoginStore()
    let spotlight = SpotlightShortcutStore()
    let dockIcon = DockIconPresence()
    lazy var newWindowOpener = NewWindowOpener(access: accessibilityAccess)
    lazy var firstRunWindow = FirstRunWindowPresenter(
        updates: updates,
        launchAtLogin: launchAtLogin,
        spotlight: spotlight,
        accessibilityAccess: accessibilityAccess,
        appShortcuts: appShortcuts,
        dockIcon: dockIcon
    )
    lazy var settings = SettingsWindowPresenter(
        updates: updates,
        accessibilityAccess: accessibilityAccess,
        appShortcuts: appShortcuts,
        launchAtLogin: launchAtLogin,
        spotlight: spotlight,
        firstRunWindow: firstRunWindow,
        dockIcon: dockIcon
    )
    lazy var hiddenAppsWindow = HiddenAppsWindowPresenter(
        hiddenApps: hiddenApps,
        appIndex: appIndex,
        appIcons: appIcons,
        dockIcon: dockIcon
    )
    lazy var shortcutEditor = AppShortcutEditorWindowPresenter(
        store: appShortcuts,
        appIndex: appIndex,
        appIcons: appIcons,
        accessibilityAccess: accessibilityAccess,
        dockIcon: dockIcon
    )
    lazy var appShortcutsWindow = AppShortcutsWindowPresenter(
        store: appShortcuts,
        appIndex: appIndex,
        appIcons: appIcons,
        shortcutEditor: shortcutEditor,
        dockIcon: dockIcon
    )
    lazy var launcherPanel = LauncherPanelPresenter(
        settings: settings,
        hiddenAppsWindow: hiddenAppsWindow,
        appShortcutsWindow: appShortcutsWindow,
        shortcutEditor: shortcutEditor,
        updates: updates,
        appIndex: appIndex,
        appIcons: appIcons,
        hiddenApps: hiddenApps,
        appShortcuts: appShortcuts,
        newWindowOpener: newWindowOpener
    )
    lazy var shortcutListener = AppShortcutListener(
        store: appShortcuts,
        appIndex: appIndex,
        runner: AppShortcutRunner(appIndex: appIndex, newWindowOpener: newWindowOpener)
    )
    lazy var iCloudSync = ICloudSyncCoordinator(appShortcuts: appShortcuts, hiddenApps: hiddenApps)

    func applicationDidFinishLaunching(_: Notification) {
        // Settled before Sparkle starts, which marks every install as launched before.
        let isFirstRun = FirstRunStatus().settleAtLaunch() == .pending
        // A move relaunches the app, so nothing below should start before the offer is settled.
        // On a first run the setup checklist makes the offer instead.
        if !isFirstRun {
            ApplicationsFolderMoveWorkflow().offerIfNeeded()
        }
        updates.start()
        appIndex.start()
        appIcons.start(observing: appIndex)
        KeyboardShortcuts.onKeyDown(for: .toggleLauncher) { [weak self] in
            self?.launcherPanel.toggle()
        }
        iCloudSync.start()
        shortcutListener.start()
        if isFirstRun {
            firstRunWindow.show()
        } else {
            Task {
                await SpotlightConflictLaunchCheck().run()
            }
        }
    }

    /// Opening the app again while it runs is the way back to Settings when the menu bar icon is
    /// hidden.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        settings.show()
        return false
    }
}
