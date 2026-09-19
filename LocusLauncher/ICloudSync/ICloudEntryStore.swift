import CryptoKit
import Foundation

/// Keeps one kind of synced entry in iCloud key-value storage. Each entry has its own key, so
/// two Macs changing different entries at once don't overwrite each other.
struct ICloudEntryStore<Entry: SyncableEntry> {
    let keyPrefix: String
    /// Where this Mac keeps the entries it and iCloud last agreed on.
    let baseDefaultsKey: String

    /// Returns this Mac's entries with the changes from iCloud applied.
    func sync(_ local: [Entry], with cloudStore: NSUbiquitousKeyValueStore) -> [Entry] {
        let base = base()
        var outcome = SyncMerge(local: local, cloud: cloudEntries(in: cloudStore, base: base), base: base).run()
        for (id, entry) in outcome.cloudWrites {
            let data = try? JSONEncoder().encode(entry)
            if let data {
                cloudStore.set(data, forKey: key(for: id))
            }
            // iCloud drops writes over its limits without an error. Recording one as agreed would
            // make the next sync read the missing entry as removed elsewhere and delete it here.
            // Keeping the old agreement makes the next sync try the write again.
            if data == nil || cloudStore.data(forKey: key(for: id)) != data {
                outcome.base[id] = base[id]
            }
        }
        for id in outcome.cloudRemovals {
            cloudStore.removeObject(forKey: key(for: id))
        }
        saveBase(outcome.base)
        return outcome.local
    }

    /// Makes the next sync merge both sides as if neither had seen the other, so nothing is
    /// removed for being missing from the other side.
    func forgetBase() {
        UserDefaults.standard.removeObject(forKey: baseDefaultsKey)
    }

    /// iCloud caps keys at 64 bytes, and bundle identifiers can be longer.
    private func key(for id: String) -> String {
        let key = keyPrefix + id
        guard key.utf8.count > 64 else { return key }
        let digest = SHA256.hash(data: Data(id.utf8)).prefix(16)
        return keyPrefix + digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Entries are read by the ID they carry, since a long ID's key doesn't contain it. An entry
    /// this version can't read, perhaps written by a newer one, counts as unchanged so it isn't
    /// removed here.
    private func cloudEntries(in cloudStore: NSUbiquitousKeyValueStore, base: [String: Entry]) -> [String: Entry] {
        let baseByKey = Dictionary(base.map { (key(for: $0.key), $0.value) }) { first, _ in first }
        var entries: [String: Entry] = [:]
        for (key, value) in cloudStore.dictionaryRepresentation where key.hasPrefix(keyPrefix) {
            if let entry = (value as? Data).flatMap({ try? JSONDecoder().decode(Entry.self, from: $0) }) {
                entries[entry.syncID] = entry
            } else if let unchanged = baseByKey[key] {
                entries[unchanged.syncID] = unchanged
            }
        }
        return entries
    }

    private func base() -> [String: Entry] {
        UserDefaults.standard.data(forKey: baseDefaultsKey)
            .flatMap { try? JSONDecoder().decode([String: Entry].self, from: $0) }
            ?? [:]
    }

    private func saveBase(_ base: [String: Entry]) {
        if let data = try? JSONEncoder().encode(base) {
            UserDefaults.standard.set(data, forKey: baseDefaultsKey)
        }
    }
}
