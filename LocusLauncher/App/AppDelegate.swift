import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let launcherPanel = LauncherPanelPresenter()

    func applicationDidFinishLaunching(_: Notification) {
        launcherPanel.show()
    }
}
