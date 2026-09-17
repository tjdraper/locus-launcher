import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let launcherPanel = LauncherPanelPresenter()
    let updates = UpdateController()

    func applicationDidFinishLaunching(_: Notification) {
        // A move relaunches the app, so nothing below should start before the offer is settled.
        ApplicationsFolderMoveWorkflow().offerIfNeeded()
        updates.start()
        launcherPanel.show()
    }
}
