import SwiftUI

struct MenuBarMenu: View {
    let launcherPanel: LauncherPanelPresenter

    var body: some View {
        Button("Show Launcher") {
            launcherPanel.show()
        }

        Divider()

        Button("Quit Locus Launcher") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
