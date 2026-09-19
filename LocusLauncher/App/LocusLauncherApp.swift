import SwiftUI

@main
struct LocusLauncherApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(
                launcherPanel: appDelegate.launcherPanel,
                settings: appDelegate.settings,
                appShortcutsWindow: appDelegate.appShortcutsWindow,
                hiddenAppsWindow: appDelegate.hiddenAppsWindow,
                firstRunWindow: appDelegate.firstRunWindow,
                updates: appDelegate.updates
            )
        } label: {
            Image(nsImage: MenuBarIcon.image(badged: appDelegate.updates.waitingUpdateVersion != nil))
        }
    }
}
