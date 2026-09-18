import Foundation
import Observation

/// The search typed into one launcher session.
@Observable
final class AppSearchSession {
    var query = ""

    @ObservationIgnored private let history: LaunchHistory
    @ObservationIgnored private var index = AppSearchIndex(apps: [])

    /// History only changes when an app is launched, which ends the session, so a copy stays
    /// current.
    init(history: LaunchHistory) {
        self.history = history
    }

    /// Nil while the query is blank, when the launcher shows the browse list instead.
    func results(in apps: [IndexedApp]) -> [IndexedApp]? {
        guard !FuzzyMatcher.fold(query).isEmpty else { return nil }

        if index.apps != apps {
            index = AppSearchIndex(apps: apps)
        }
        return index.results(for: query, history: history, at: .now)
    }
}
