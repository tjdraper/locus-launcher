import Foundation

nonisolated struct IndexedApp: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let bundleIdentifier: String?

    var id: URL {
        url
    }
}
