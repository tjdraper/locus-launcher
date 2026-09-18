import Foundation

/// Which apps were launched after typing which search terms. Each launch's weight halves every
/// couple of weeks, so recent picks outrank old habits.
nonisolated struct LaunchHistory: Codable, Equatable, Sendable {
    struct Entry: Codable, Equatable, Sendable {
        let term: String
        let appURL: URL
        var weight: Double
        var updated: Date

        func weight(at date: Date) -> Double {
            weight * pow(0.5, date.timeIntervalSince(updated) / LaunchHistory.halfLife)
        }
    }

    static let halfLife: TimeInterval = 14 * 24 * 60 * 60
    /// About seven weeks after a single launch.
    private static let forgottenWeight = 0.1
    private static let maxEntries = 1000

    private(set) var entries: [Entry] = []

    /// Takes a term already passed through `FuzzyMatcher.fold`.
    mutating func record(term: String, appURL: URL, at date: Date) {
        guard !term.isEmpty else { return }

        if let index = entries.firstIndex(where: { $0.term == term && $0.appURL == appURL }) {
            entries[index].weight = entries[index].weight(at: date) + 1
            entries[index].updated = date
        } else {
            entries.append(Entry(term: term, appURL: appURL, weight: 1, updated: date))
        }
        entries.removeAll { $0.weight(at: date) < Self.forgottenWeight }
        if entries.count > Self.maxEntries {
            entries = Array(entries.sorted { $0.weight(at: date) > $1.weight(at: date) }.prefix(Self.maxEntries))
        }
    }

    /// How much each app's past launches favor it for a term, taking a term already passed through
    /// `FuzzyMatcher.fold`. Launches after typing a longer term that starts with this one count in
    /// proportion to how much of it has been typed, so an app picked for exactly this term outranks
    /// one picked as often for a longer term.
    func boosts(for term: String, at date: Date) -> [URL: Double] {
        guard !term.isEmpty else { return [:] }

        var boosts: [URL: Double] = [:]
        for entry in entries where entry.term.hasPrefix(term) {
            let typedShare = Double(term.count) / Double(entry.term.count)
            boosts[entry.appURL, default: 0] += entry.weight(at: date) * typedShare
        }
        return boosts
    }
}
