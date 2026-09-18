import KeyboardShortcuts
import SwiftUI

/// Offers to free a shortcut from Spotlight for the launcher, or to give Spotlight back a shortcut
/// this app turned off.
struct SpotlightShortcutRows: View {
    let store: SpotlightShortcutStore

    var body: some View {
        if !store.conflictingShortcuts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Spotlight also uses \(names(of: store.conflictingShortcuts)), so it opens instead of the launcher.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .symbolRenderingMode(.multicolor)
                HStack {
                    Button("Turn Off Spotlight’s Shortcut") {
                        Task { await store.turnOffConflictingShortcuts() }
                    }
                    Button("Open Keyboard Settings") {
                        store.openKeyboardSettings()
                    }
                    .buttonStyle(.link)
                }
                .disabled(store.isChanging)
            }
        }

        if let spotlightSearch = store.spotlightSearchShortcut {
            let name = names(of: [spotlightSearch])
            LabeledContent {
                Button("Turn Off") {
                    Task { await store.turnOffSpotlightSearchShortcut() }
                }
                .disabled(store.isChanging)
            } label: {
                Text("Spotlight is using \(name)")
                Text("Turn off Spotlight’s shortcut to set the launcher shortcut to \(name).")
            }
        }

        if !store.shortcutsTurnedOffByApp.isEmpty {
            LabeledContent {
                Button("Turn Back On") {
                    Task { await store.turnShortcutsBackOn() }
                }
                .disabled(store.isChanging)
            } label: {
                Text("Spotlight’s \(names(of: store.shortcutsTurnedOffByApp)) shortcut is off")
            }
        }

        if store.changeFailed {
            Text("Couldn’t change Spotlight’s shortcut. Change it in Keyboard Settings under Keyboard Shortcuts › Spotlight.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func names(of entries: [SpotlightHotKeys.Entry]) -> String {
        SpotlightShortcutStore.displayNames(of: entries)
    }
}
