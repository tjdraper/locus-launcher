import Foundation

/// Decides which app bundles on disk count as launchable apps, and which copy wins when the same
/// app is installed in more than one place.
///
/// Spotlight reports every app bundle it has indexed, including updater helpers, apps nested
/// inside other apps, installers left in Downloads, Xcode build products and apps on mounted disk
/// images. Only the standard app folders are trusted outright. Everywhere else, an app is listed
/// unless it sits somewhere people keep things they don't launch directly.
nonisolated struct AppLocationPolicy: Sendable {
    /// In order of preference when the same app is installed more than once.
    let standardFolders: [String]

    /// Apps that live outside the standard folders but belong in the launcher.
    let standaloneApps: [String]

    private let excludedPrefixes: [String]

    init(homeDirectory: String) {
        standardFolders = [
            "/Applications",
            "/System/Applications",
            "\(homeDirectory)/Applications",
            "/System/Library/CoreServices/Applications",
        ]
        standaloneApps = [
            "/System/Library/CoreServices/Finder.app",
        ]
        excludedPrefixes = [
            "\(homeDirectory)/Downloads/",
            "/System/",
            "/private/",
            // macOS moves apps it finds incompatible during an upgrade into numbered folders here.
            "/Users/Shared/Previously Relocated Items",
        ]
    }

    static let current = AppLocationPolicy(homeDirectory: NSHomeDirectory())

    /// `isOnDiskImage` is only called when the path alone can't decide, since answering it means
    /// asking Disk Arbitration about the volume.
    func isIncluded(path rawPath: String, isOnDiskImage: () -> Bool) -> Bool {
        let path = Self.normalized(rawPath)
        guard (path as NSString).pathExtension.lowercased() == "app" else {
            return false
        }

        let ancestors = path.split(separator: "/").dropLast()
        if ancestors.contains(where: Self.isBundle) {
            return false
        }

        if standaloneApps.contains(path) || standardFolders.contains(where: { Self.path(path, isInside: $0) }) {
            return true
        }

        if ancestors.contains(where: Self.isExcludedFolder) || excludedPrefixes.contains(where: path.hasPrefix) {
            return false
        }

        return !isOnDiskImage()
    }

    /// Lower ranks are preferred.
    func preferenceRank(path rawPath: String) -> Int {
        let path = Self.normalized(rawPath)
        if let index = standardFolders.firstIndex(where: { Self.path(path, isInside: $0) }) {
            return index
        }
        if standaloneApps.contains(path) {
            return standardFolders.count
        }
        return standardFolders.count + 1
    }

    /// The boot volume's writable half is also reachable through its firmlinked mount point, so the
    /// same app can be reported under two paths.
    static func normalized(_ path: String) -> String {
        let dataVolume = "/System/Volumes/Data/"
        guard path.hasPrefix(dataVolume) else {
            return path
        }
        return "/" + path.dropFirst(dataVolume.count)
    }

    private static func path(_ path: String, isInside folder: String) -> Bool {
        path.hasPrefix(folder + "/")
    }

    private static func isBundle(_ component: Substring) -> Bool {
        bundleExtensions.contains((String(component) as NSString).pathExtension.lowercased())
    }

    /// Hidden folders cover the Trash, Time Machine and build caches.
    private static func isExcludedFolder(_ component: Substring) -> Bool {
        component.hasPrefix(".") || component == "Library" || component == "Backups.backupdb"
    }

    private static let bundleExtensions: Set<String> = [
        "app", "appex", "bundle", "framework", "plugin", "xcarchive", "xpc",
    ]
}
