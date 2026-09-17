import SwiftUI

@main
struct LocusLauncherApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Locus Launcher", systemImage: "square.grid.2x2") {
            MenuBarMenu(launcherPanel: appDelegate.launcherPanel)
        }
    }
}
