import Foundation

/// The indexed apps prepared for fuzzy matching, ranked for each query.
nonisolated struct AppSearchIndex: Sendable {
    let apps: [IndexedApp]
    private let matchers: [FuzzyMatcher]

    init(apps: [IndexedApp]) {
        self.apps = apps
        matchers = apps.map { FuzzyMatcher(name: $0.name) }
    }

    /// Apps launched for this term before come first, then the best matches, then shorter names,
    /// so "mail" puts Mail above Mailplane.
    func results(for query: String, history: LaunchHistory, at date: Date) -> [IndexedApp] {
        let term = FuzzyMatcher.fold(query)
        let characters = Array(term)
        let boosts = history.boosts(for: term, at: date)

        struct Ranked {
            let app: IndexedApp
            let boost: Double
            let score: Int
        }
        let ranked = zip(apps, matchers).compactMap { app, matcher in
            matcher.score(characters).map { Ranked(app: app, boost: boosts[app.url] ?? 0, score: $0) }
        }
        return ranked.sorted { lhs, rhs in
            if lhs.boost != rhs.boost {
                return lhs.boost > rhs.boost
            }
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            if lhs.app.name.count != rhs.app.name.count {
                return lhs.app.name.count < rhs.app.name.count
            }
            return lhs.app.name.localizedStandardCompare(rhs.app.name) == .orderedAscending
        }
        .map(\.app)
    }
}
