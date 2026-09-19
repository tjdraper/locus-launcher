/// The hot key the launcher shows in each app's row, keyed by the app's `persistentID`. Only the
/// first recorded one is shown, to keep rows uncluttered.
enum AppShortcutRowLabels {
    static func make(from list: AppShortcutList) -> [String: String] {
        list.recordedEntriesByAppID.compactMapValues { entries in
            entries.first?.keys?.symbols
        }
    }
}
