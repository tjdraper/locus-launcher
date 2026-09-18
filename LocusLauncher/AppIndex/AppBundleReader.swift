import Foundation

nonisolated enum AppBundleReader {
    static func read(_ url: URL) -> IndexedApp {
        IndexedApp(url: url, name: displayName(of: url), bundleIdentifier: bundleIdentifier(of: url))
    }

    /// Finder's localized name, which follows the user's language. It keeps the `.app` extension
    /// when Finder is set to show all extensions.
    private static func displayName(of url: URL) -> String {
        let name = (try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName)
            ?? url.lastPathComponent
        guard name.lowercased().hasSuffix(".app") else {
            return name
        }
        return String(name.dropLast(4))
    }

    /// `Bundle(url:)` caches every bundle it opens for the life of the process, which would keep
    /// stale info for apps that update in place.
    private static func bundleIdentifier(of url: URL) -> String? {
        let info = CFBundleCopyInfoDictionaryForURL(url as CFURL) as? [String: Any]
        return info?[kCFBundleIdentifierKey as String] as? String
    }
}
