import Foundation

/// Keeps one copy of each app, so an old copy in another folder doesn't show up next to the one in
/// `/Applications`.
nonisolated struct DuplicateAppResolver {
    let policy: AppLocationPolicy

    func resolve(_ apps: [IndexedApp]) -> [IndexedApp] {
        Dictionary(grouping: apps, by: identity)
            .values
            .compactMap { copies in copies.min(by: isPreferred) }
    }

    /// Apps without a bundle identifier can't be matched to another copy, so each stands alone.
    private func identity(of app: IndexedApp) -> String {
        app.bundleIdentifier?.lowercased() ?? app.url.path
    }

    private func isPreferred(_ lhs: IndexedApp, over rhs: IndexedApp) -> Bool {
        let lhsRank = policy.preferenceRank(path: lhs.url.path)
        let rhsRank = policy.preferenceRank(path: rhs.url.path)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        if lhs.url.path.count != rhs.url.path.count {
            return lhs.url.path.count < rhs.url.path.count
        }
        return lhs.url.path < rhs.url.path
    }
}
