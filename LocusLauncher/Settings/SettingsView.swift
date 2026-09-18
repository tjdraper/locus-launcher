import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    let updates: UpdateController
    let launchAtLogin: LaunchAtLoginStore
    let spotlight: SpotlightShortcutStore

    var body: some View {
        Form {
            Section {
                LaunchAtLoginToggle(store: launchAtLogin)
            }

            Section("Launcher") {
                KeyboardShortcuts.Recorder("Launcher shortcut", name: .toggleLauncher) { _ in
                    spotlight.refresh()
                }
                // The only menu is this app's own, which exists while Settings is open. AppKit fills
                // it with items like Emoji & Symbols, and a global hotkey fires before any menu sees
                // the keys, so those are never real conflicts.
                .keyboardShortcutsConflictPolicy(.init(menuItem: .allow))
                SpotlightShortcutRows(store: spotlight)
            }

            UpdateSettingsSection(updates: updates)
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
        .task {
            // Either setting can change in System Settings while this window is open or closed.
            refresh()
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                refresh()
            }
        }
    }

    private func refresh() {
        launchAtLogin.refresh()
        spotlight.refresh()
    }
}

#Preview {
    SettingsView(updates: UpdateController(), launchAtLogin: LaunchAtLoginStore(), spotlight: SpotlightShortcutStore())
}
