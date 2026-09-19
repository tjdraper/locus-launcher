import Foundation

/// The apps the user hid from the launcher, which drop out of both browse and search.
nonisolated struct HiddenAppList: Codable, Equatable, Sendable {
    struct Entry: Codable, Equatable, Identifiable, Sendable {
        /// The app's `persistentID`.
        let id: String
        var name: String
        var url: URL
        var syncsToOtherMacs: Bool

        /// A path means nothing on another Mac.
        var canSync: Bool {
            !id.hasPrefix("/")
        }
    }

    private(set) var entries: [Entry] = []

    mutating func hide(_ app: IndexedApp) {
        let id = app.persistentID
        guard !entries.contains(where: { $0.id == id }) else { return }
        entries.append(Entry(id: id, name: app.name, url: app.url, syncsToOtherMacs: app.bundleIdentifier != nil))
    }

    mutating func unhide(_ id: String) {
        entries.removeAll { $0.id == id }
    }

    mutating func setSyncsToOtherMacs(_ syncs: Bool, for id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }), entries[index].canSync else { return }
        entries[index].syncsToOtherMacs = syncs
    }

    /// Keeps the order of `apps`.
    func visibleApps(in apps: [IndexedApp]) -> [IndexedApp] {
        guard !entries.isEmpty else { return apps }
        let hidden = Set(entries.map(\.id))
        return apps.filter { !hidden.contains($0.persistentID) }
    }
}
