import Foundation

/// Keeps launch history in user defaults. It stays on this Mac, since installed apps differ
/// between Macs.
final class LaunchHistoryStore {
    private static let defaultsKey = "LaunchHistory"

    private(set) var history: LaunchHistory

    init() {
        history = UserDefaults.standard.data(forKey: Self.defaultsKey)
            .flatMap { try? JSONDecoder().decode(LaunchHistory.self, from: $0) }
            ?? LaunchHistory()
    }

    func record(_ app: IndexedApp, searchedFor query: String) {
        let term = FuzzyMatcher.fold(query)
        guard !term.isEmpty else { return }

        history.record(term: term, appURL: app.url, at: .now)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
