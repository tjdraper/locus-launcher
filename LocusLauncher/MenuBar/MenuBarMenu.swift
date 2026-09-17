import SwiftUI

struct MenuBarMenu: View {
    let launcherPanel: LauncherPanelPresenter
    let updates: UpdateController

    var body: some View {
        Button("Show Launcher") {
            launcherPanel.show()
        }

        Divider()

        Button("Check for Updates…") {
            updates.checkForUpdates()
        }
        .disabled(!updates.canCheckForUpdates)

        Divider()

        Button("Quit Locus Launcher") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
