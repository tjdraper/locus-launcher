import Foundation

nonisolated struct IndexedApp: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let bundleIdentifier: String?
    /// The later of when the app's Info.plist and its top folder last changed, which tells when the
    /// icon may have changed. Every update rewrites the Info.plist, even one that patches the
    /// bundle in place, and a custom icon set in Finder adds a file to the top folder.
    var lastModified: Date?

    var id: URL {
        url
    }
}
