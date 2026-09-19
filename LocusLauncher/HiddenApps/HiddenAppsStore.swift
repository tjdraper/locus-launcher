import Foundation
import Observation

/// Keeps the hidden apps in user defaults.
@Observable
final class HiddenAppsStore {
    private static let defaultsKey = "HiddenApps"

    private(set) var list: HiddenAppList {
        didSet {
            if let data = try? JSONEncoder().encode(list) {
                UserDefaults.standard.set(data, forKey: Self.defaultsKey)
            }
        }
    }

    init() {
        list = UserDefaults.standard.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode(HiddenAppList.self, from: $0) }
            ?? HiddenAppList()
    }

    func hide(_ app: IndexedApp) {
        list.hide(app)
    }

    func unhide(_ id: String) {
        list.unhide(id)
    }

    func setSyncsToOtherMacs(_ syncs: Bool, for id: String) {
        list.setSyncsToOtherMacs(syncs, for: id)
    }

    func replaceEntries(_ entries: [HiddenAppList.Entry]) {
        list = HiddenAppList(entries: entries)
    }
}
