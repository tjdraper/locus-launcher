import SwiftUI

struct MenuBarMenu: View {
    let launcherPanel: LauncherPanelPresenter
    let settings: SettingsWindowPresenter
    let appShortcutsWindow: AppShortcutsWindowPresenter
    let hiddenAppsWindow: HiddenAppsWindowPresenter
    let firstRunWindow: FirstRunWindowPresenter
    let updates: UpdateController

    var body: some View {
        Button("Show Launcher") {
            launcherPanel.show()
        }

        Button("Settings…") {
            settings.show()
        }
        .keyboardShortcut(",")

        Button("App Hot Keys…") {
            appShortcutsWindow.show()
        }
        .keyboardShortcut("k", modifiers: [.command, .option])

        Button("Hidden Apps…") {
            hiddenAppsWindow.show()
        }
        .keyboardShortcut("h", modifiers: [.command, .option, .control])

        Button("Setup Checklist…") {
            firstRunWindow.show()
        }

        Divider()

        if let version = updates.waitingUpdateVersion {
            Button("Install Update \(version)…") {
                updates.checkForUpdates()
            }
        }

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
