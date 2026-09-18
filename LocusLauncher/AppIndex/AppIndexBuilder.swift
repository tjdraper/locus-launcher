import Foundation

/// Turns the raw list of app bundles from Spotlight and the folder scan into the apps the launcher
/// shows. Runs off the main actor because it reads every app's Info.plist.
nonisolated struct AppIndexBuilder {
    let policy: AppLocationPolicy

    @concurrent
    func build(spotlightResults: [URL]) async -> [IndexedApp] {
        let detector = DiskImageDetector()
        let candidates = Set((AppFolderScanner(policy: policy).scan() + spotlightResults).map { url in
            URL(fileURLWithPath: AppLocationPolicy.normalized(url.standardizedFileURL.path))
        })

        let apps = candidates
            .filter { url in
                policy.isIncluded(path: url.path) { detector.isOnDiskImage(url) }
            }
            .map(AppBundleReader.read)

        return DuplicateAppResolver(policy: policy)
            .resolve(apps)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
