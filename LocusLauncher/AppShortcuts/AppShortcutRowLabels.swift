/// The hot keys the launcher shows in each app's row, keyed by the app's `persistentID`.
enum AppShortcutRowLabels {
    private static let shownPerRow = 2

    static func make(from list: AppShortcutList) -> [String: String] {
        list.recordedEntriesByAppID.mapValues { entries in
            let symbols = entries.compactMap(\.keys?.symbols)
            let shown = symbols.prefix(shownPerRow).joined(separator: "  ")
            return symbols.count > shownPerRow ? "\(shown)  +\(symbols.count - shownPerRow)" : shown
        }
    }
}
