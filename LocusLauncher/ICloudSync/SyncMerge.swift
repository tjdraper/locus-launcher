import Foundation

/// An entry the user can choose to share with their other Macs.
nonisolated protocol SyncableEntry: Codable, Equatable, Sendable {
    /// Unique within its kind of entry, and the same on every Mac.
    var syncID: String { get }
    /// The user's choice, and whether other Macs could recognize the entry.
    var isSynced: Bool { get }
    /// False while the entry is being edited into shape, such as a hot key waiting for new keys.
    var isReadyToSync: Bool { get }
}

/// Brings one kind of entry on this Mac and in iCloud into agreement.
///
/// Each side is compared with `base`, the entries both sides agreed on last time, so the merge
/// can tell which side changed. That lets a removal on one Mac win over an entry the other side
/// still has. When both sides changed the same entry, iCloud wins, since that's the version the
/// other Macs already have.
nonisolated struct SyncMerge<Entry: SyncableEntry> {
    struct Outcome {
        var local: [Entry]
        var cloudWrites: [String: Entry] = [:]
        var cloudRemovals: Set<String> = []
        var base: [String: Entry] = [:]
    }

    let local: [Entry]
    let cloud: [String: Entry]
    let base: [String: Entry]

    func run() -> Outcome {
        var outcome = Outcome(local: local)
        let synced = Dictionary(local.filter { $0.isSynced && $0.isReadyToSync }.map { ($0.syncID, $0) }) { first, _ in first }
        let localOnly = Set(local.filter { !$0.isSynced }.map(\.syncID))
        let notReady = Set(local.filter { $0.isSynced && !$0.isReadyToSync }.map(\.syncID))
        let ids = Set(synced.keys).union(cloud.keys).union(base.keys)

        // Sorted so entries that arrive together land in the same order on every Mac.
        for id in ids.sorted() {
            // Leaves other Macs' copy alone until the edit here settles one way or the other.
            if notReady.contains(id) {
                outcome.base[id] = base[id]
                continue
            }

            // Turning sync off keeps the entry here and removes it from the other Macs. An entry
            // this Mac keeps to itself is left alone otherwise, even when another Mac syncs one
            // with the same ID.
            if localOnly.contains(id) {
                if base[id] != nil, cloud[id] != nil {
                    outcome.cloudRemovals.insert(id)
                }
                continue
            }

            let mine = synced[id]
            let theirs = cloud[id]
            let agreed: Entry?
            if mine == theirs {
                agreed = mine
            } else if mine == base[id] {
                agreed = theirs
                outcome.local.replace(id: id, with: theirs)
            } else if theirs == base[id] {
                agreed = mine
                outcome.writeToCloud(mine, id: id)
            } else if theirs == nil {
                // Changed here and removed elsewhere: keeping the change loses less.
                agreed = mine
                outcome.writeToCloud(mine, id: id)
            } else {
                agreed = theirs
                outcome.local.replace(id: id, with: theirs)
            }
            outcome.base[id] = agreed
        }
        return outcome
    }
}

nonisolated private extension SyncMerge.Outcome {
    mutating func writeToCloud(_ entry: Entry?, id: String) {
        if let entry {
            cloudWrites[id] = entry
        } else {
            cloudRemovals.insert(id)
        }
    }
}

nonisolated private extension Array where Element: SyncableEntry {
    mutating func replace(id: String, with entry: Element?) {
        let index = firstIndex { $0.syncID == id }
        switch (index, entry) {
        case let (index?, entry?): self[index] = entry
        case let (index?, nil): remove(at: index)
        case let (nil, entry?): append(entry)
        case (nil, nil): break
        }
    }
}
