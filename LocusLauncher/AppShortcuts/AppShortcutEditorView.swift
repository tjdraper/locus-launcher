import KeyboardShortcuts
import SwiftUI

/// Lists one app's hot keys, and adds, changes and removes them.
struct AppShortcutEditorView: View {
    let appID: String
    let appName: String
    let store: AppShortcutStore
    let appIndex: AppIndexStore
    let appIcons: AppIconCache
    let accessibilityAccess: AccessibilityAccessStore

    var body: some View {
        Form {
            Section {
                ForEach(entries) { entry in
                    AppShortcutRow(
                        entry: entry,
                        clash: AppShortcutConflictCheck(store: store).clash(for: entry, installedAppIDs: installedAppIDs),
                        store: store
                    )
                }
            } header: {
                HStack(spacing: 12) {
                    Image(nsImage: installedApp.flatMap(appIcons.cachedIcon(for:)) ?? appIcons.placeholder)
                        .frame(width: AppIconCache.pointSize, height: AppIconCache.pointSize)
                    VStack(alignment: .leading) {
                        Text(installedApp?.name ?? appName)
                            .font(.headline)
                        if installedApp == nil {
                            Text("Not on this Mac")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Add Hot Key") {
                        if let app = installedApp {
                            store.add(for: app)
                        }
                    }
                    .disabled(installedApp == nil)
                    if !accessibilityAccess.isGranted, entries.contains(where: { $0.action == .newWindow }) {
                        AccessibilityAccessNote(store: accessibilityAccess)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        // Sizes the window to its rows, which grow as hot keys are added.
        .fixedSize()
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                accessibilityAccess.refresh()
            }
        }
    }

    private var entries: [AppShortcutList.Entry] {
        store.list.entries(forAppID: appID)
    }

    private var installedApp: IndexedApp? {
        appIndex.apps.first { $0.persistentID == appID }
    }

    private var installedAppIDs: Set<String> {
        Set(appIndex.apps.map(\.persistentID))
    }
}

private struct AppShortcutRow: View {
    let entry: AppShortcutList.Entry
    /// Set when a hot key synced from another Mac brought keys this Mac already uses.
    let clash: AppShortcutConflictCheck.Conflict?
    let store: AppShortcutStore

    /// The entry keeps no keys while its recorder shows rejected ones.
    @State private var rejected: RejectedShortcut?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                recorder
                controls
            }
            if let rejected {
                ShortcutConflictNote(
                    reason: rejected.conflict.reason,
                    onUseHere: useHereAction(for: rejected.conflict, keys: AppShortcutList.Keys(rejected.shortcut))
                )
            } else if let clash, let keys = entry.keys {
                ShortcutConflictNote(reason: clash.reason, onUseHere: useHereAction(for: clash, keys: keys))
            } else if entry.keys?.shortcut.isTakenBySystem == true {
                SystemShortcutNote()
            }
        }
    }

    private var recorder: some View {
        // A row with no keys is one the user just added, so it's ready to record.
        AppShortcutRecorder(
            shortcut: rejected?.shortcut ?? entry.keys?.shortcut,
            recordsOnAppear: entry.keys == nil,
            onChange: record
        )
        .fixedSize()
        .rejectedShortcutOutline(rejected != nil || clash != nil)
    }

    /// The launcher's shortcut isn't offered, since taking it would leave the launcher with none.
    private func useHereAction(for conflict: AppShortcutConflictCheck.Conflict, keys: AppShortcutList.Keys) -> (() -> Void)? {
        guard case .appShortcut = conflict else { return nil }
        return {
            self.rejected = nil
            store.takeKeys(keys, for: entry.id)
        }
    }

    private func record(_ shortcut: KeyboardShortcuts.Shortcut?) {
        if let shortcut, let conflict = AppShortcutConflictCheck(store: store).conflict(for: shortcut, recording: .appShortcut(entry.id)) {
            rejected = RejectedShortcut(shortcut: shortcut, conflict: conflict)
            store.setKeys(nil, for: entry.id)
        } else {
            rejected = nil
            store.setKeys(shortcut.map(AppShortcutList.Keys.init), for: entry.id)
        }
    }

    @ViewBuilder
    private var controls: some View {
        Picker("Action", selection: Binding(
            get: { entry.action },
            set: { store.setAction($0, for: entry.id) }
        )) {
            ForEach(AppShortcutList.Action.allCases, id: \.self) { action in
                Text(action.title)
            }
        }
        .labelsHidden()
        .fixedSize()
        Spacer()
        Toggle("Sync to other Macs", isOn: Binding(
            get: { entry.syncsToOtherMacs },
            set: { store.setSyncsToOtherMacs($0, for: entry.id) }
        ))
        .toggleStyle(.checkbox)
        .fixedSize()
        .disabled(!entry.canSync)
        .help(entry.canSync ? "" : "This app has no bundle identifier, so other Macs can’t recognize it.")
        Button("Remove", systemImage: "minus.circle") {
            store.remove(entry.id)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }
}

private struct AccessibilityAccessNote: View {
    let store: AccessibilityAccessStore

    var body: some View {
        HStack {
            Text("Without Accessibility access, New Window only brings the app forward.")
                .foregroundStyle(.secondary)
            Button("Allow…") {
                store.requestAccess()
            }
        }
    }
}
