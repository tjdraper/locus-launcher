import Foundation
import Observation

/// Keeps the apps' hot keys in user defaults.
@Observable
final class AppShortcutStore {
    private static let defaultsKey = "AppShortcuts"

    private(set) var list: AppShortcutList {
        didSet {
            if let data = try? JSONEncoder().encode(list) {
                UserDefaults.standard.set(data, forKey: Self.defaultsKey)
            }
        }
    }

    init() {
        list = UserDefaults.standard.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode(AppShortcutList.self, from: $0) }
            ?? AppShortcutList()
    }

    func add(for app: IndexedApp) {
        list.add(for: app)
    }

    func remove(_ id: UUID) {
        list.remove(id)
    }

    func setKeys(_ keys: AppShortcutList.Keys?, for id: UUID) {
        list.setKeys(keys, for: id)
    }

    func takeKeys(_ keys: AppShortcutList.Keys, for id: UUID) {
        list.takeKeys(keys, for: id)
    }

    func releaseKeys(_ keys: AppShortcutList.Keys) {
        list.releaseKeys(keys)
    }

    func setAction(_ action: AppShortcutList.Action, for id: UUID) {
        list.setAction(action, for: id)
    }

    func setSyncsToOtherMacs(_ syncs: Bool, for id: UUID) {
        list.setSyncsToOtherMacs(syncs, for: id)
    }

    func removeAll(forAppID appID: String) {
        list.removeAll(forAppID: appID)
    }

    func removeUnrecorded(forAppID appID: String) {
        list.removeUnrecorded(forAppID: appID)
    }

    func replaceEntries(_ entries: [AppShortcutList.Entry]) {
        list = AppShortcutList(entries: entries)
    }
}
