import AppKit
import SwiftUI

struct SettingsView: View {
    let updates: UpdateController
    let launchAtLogin: LaunchAtLoginStore
    let spotlight: SpotlightShortcutStore
    let accessibilityAccess: AccessibilityAccessStore
    let appShortcuts: AppShortcutStore
    let onShowSetup: () -> Void

    var body: some View {
        Form {
            Section {
                LaunchAtLoginToggle(store: launchAtLogin)
            }

            Section("Launcher") {
                LauncherShortcutRow(appShortcuts: appShortcuts, spotlight: spotlight)
                SpotlightShortcutRows(store: spotlight)
            }

            Section("Permissions") {
                AccessibilityAccessRow(store: accessibilityAccess)
            }

            UpdateSettingsSection(updates: updates)

            Section {
                LabeledContent {
                    Button("Show…", action: onShowSetup)
                } label: {
                    Text("Setup checklist")
                    Text("Every setup step on one page, as shown on first launch.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
        .task {
            // These settings can change in System Settings while this window is open or closed.
            refresh()
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                refresh()
            }
        }
    }

    private func refresh() {
        launchAtLogin.refresh()
        spotlight.refresh()
        accessibilityAccess.refresh()
    }
}

#Preview {
    SettingsView(
        updates: UpdateController(),
        launchAtLogin: LaunchAtLoginStore(),
        spotlight: SpotlightShortcutStore(),
        accessibilityAccess: AccessibilityAccessStore(),
        appShortcuts: AppShortcutStore(),
        onShowSetup: { print("Show setup") }
    )
}
