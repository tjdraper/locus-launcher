import KeyboardShortcuts

/// The hot key the launcher shows in each app's row, keyed by the app's `persistentID`. Only the
/// first one that works on this Mac is shown, to keep rows uncluttered.
enum AppShortcutRowLabels {
    static func make(from list: AppShortcutList, installedAppIDs: Set<String>) -> [String: String] {
        let launcherKeys = KeyboardShortcuts.getShortcut(for: .toggleLauncher).map(AppShortcutList.Keys.init)
        let working = list.workingEntries(installedAppIDs: installedAppIDs)
        return list.recordedEntriesByAppID.compactMapValues { entries in
            entries.first { entry in
                guard let keys = entry.keys else { return false }
                return working[keys]?.id == entry.id && keys != launcherKeys
            }?.keys?.symbols
        }
    }
}
