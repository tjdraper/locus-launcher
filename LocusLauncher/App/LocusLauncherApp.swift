import SwiftUI

@main
struct LocusLauncherApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(
                launcherPanel: appDelegate.launcherPanel,
                settings: appDelegate.settings,
                updates: appDelegate.updates
            )
        } label: {
            Image(nsImage: MenuBarIcon.image(badged: appDelegate.updates.waitingUpdateVersion != nil))
        }
    }
}
