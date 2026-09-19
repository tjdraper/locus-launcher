import Foundation

/// The global hot keys the user assigned to apps. An app can have any number, each opening the
/// app or a new window in it.
nonisolated struct AppShortcutList: Codable, Equatable, Sendable {
    /// A key combination in the Carbon form global hot keys are registered with.
    struct Keys: Codable, Hashable, Sendable {
        let carbonKeyCode: Int
        let carbonModifiers: Int
    }

    enum Action: String, Codable, CaseIterable, Sendable {
        case open
        case newWindow

        var title: String {
            switch self {
            case .open: "Open"
            case .newWindow: "New Window"
            }
        }
    }

    struct Entry: Codable, Equatable, Identifiable, Sendable {
        let id: UUID
        /// The app's `persistentID`.
        let appID: String
        /// Names the app when it isn't installed.
        var appName: String
        /// Nil until the user records a combination.
        var keys: Keys?
        var action: Action
        var syncsToOtherMacs: Bool

        /// A path means nothing on another Mac.
        var canSync: Bool {
            !appID.hasPrefix("/")
        }
    }

    private(set) var entries: [Entry] = []

    /// In the order they were added.
    func entries(forAppID appID: String) -> [Entry] {
        entries.filter { $0.appID == appID }
    }

    /// Only entries with recorded keys, grouped by app.
    var recordedEntriesByAppID: [String: [Entry]] {
        Dictionary(grouping: entries.filter { $0.keys != nil }, by: \.appID)
    }

    func entry(using keys: Keys, except id: UUID? = nil) -> Entry? {
        entries.first { $0.keys == keys && $0.id != id }
    }

    @discardableResult
    mutating func add(for app: IndexedApp) -> UUID {
        let appID = app.persistentID
        let entry = Entry(
            id: UUID(),
            appID: appID,
            appName: app.name,
            keys: nil,
            action: .open,
            syncsToOtherMacs: app.bundleIdentifier != nil
        )
        entries.append(entry)
        return entry.id
    }

    mutating func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
    }

    /// Leaves the entry unchanged when another entry already uses the keys, so a combination
    /// never opens two things.
    mutating func setKeys(_ keys: Keys?, for id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        if let keys, entry(using: keys, except: id) != nil {
            return
        }
        entries[index].keys = keys
    }

    /// Gives the keys to this entry and takes them from the entry that had them. That entry is
    /// removed when it belongs to another app, since nothing shows it there until its app's hot
    /// keys are opened.
    mutating func takeKeys(_ keys: Keys, for id: UUID) {
        guard let appID = entries.first(where: { $0.id == id })?.appID else { return }
        if let previous = entries.firstIndex(where: { $0.keys == keys && $0.id != id }) {
            if entries[previous].appID == appID {
                entries[previous].keys = nil
            } else {
                entries.remove(at: previous)
            }
        }
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].keys = keys
        }
    }

    /// Frees the keys for the launcher by removing the entry that has them.
    mutating func releaseKeys(_ keys: Keys) {
        entries.removeAll { $0.keys == keys }
    }

    mutating func setAction(_ action: Action, for id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].action = action
    }

    mutating func setSyncsToOtherMacs(_ syncs: Bool, for id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }), entries[index].canSync else { return }
        entries[index].syncsToOtherMacs = syncs
    }

    mutating func removeAll(forAppID appID: String) {
        entries.removeAll { $0.appID == appID }
    }

    /// Drops entries the user added but never recorded keys for.
    mutating func removeUnrecorded(forAppID appID: String) {
        entries.removeAll { $0.appID == appID && $0.keys == nil }
    }
}
