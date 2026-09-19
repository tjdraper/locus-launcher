import KeyboardShortcuts
import SwiftUI

/// Records the launcher's hotkey. Keys an app hot key already uses are shown in red, and the
/// launcher keeps its current shortcut until the user picks free keys or moves them over.
struct LauncherShortcutRow: View {
    let appShortcuts: AppShortcutStore
    let spotlight: SpotlightShortcutStore

    @State private var rejected: RejectedShortcut?
    @State private var shortcut = KeyboardShortcuts.getShortcut(for: .toggleLauncher)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Launcher shortcut") {
                AppShortcutRecorder(shortcut: rejected?.shortcut ?? shortcut, recordsOnAppear: false, onChange: record)
                    .fixedSize()
                    .rejectedShortcutOutline(rejected != nil)
            }
            if let rejected {
                ShortcutConflictNote(reason: rejected.conflict.reason) {
                    appShortcuts.releaseKeys(AppShortcutList.Keys(rejected.shortcut))
                    use(rejected.shortcut)
                }
            } else if let shortcut, shortcut.isTakenBySystem, spotlight.conflictingShortcuts.isEmpty {
                // Spotlight's own rows explain a clash with Spotlight and offer to fix it.
                SystemShortcutNote()
            }
        }
        .task {
            // Settings and the setup checklist both record this shortcut, and either window can
            // stay open while the other changes it.
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didBecomeKeyNotification) where rejected == nil {
                shortcut = KeyboardShortcuts.getShortcut(for: .toggleLauncher)
            }
        }
    }

    private func record(_ newShortcut: KeyboardShortcuts.Shortcut?) {
        if let newShortcut, let conflict = AppShortcutConflictCheck(store: appShortcuts).conflict(for: newShortcut, recording: .launcher) {
            rejected = RejectedShortcut(shortcut: newShortcut, conflict: conflict)
        } else {
            use(newShortcut)
        }
    }

    private func use(_ newShortcut: KeyboardShortcuts.Shortcut?) {
        rejected = nil
        KeyboardShortcuts.setShortcut(newShortcut, for: .toggleLauncher)
        shortcut = newShortcut
        spotlight.refresh()
    }
}
