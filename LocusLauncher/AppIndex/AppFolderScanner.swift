import Foundation

/// Lists the apps in the standard folders straight from disk, so the index is complete even when
/// Spotlight indexing is off or hasn't finished.
nonisolated struct AppFolderScanner {
    let policy: AppLocationPolicy

    func scan() -> [URL] {
        let fileManager = FileManager.default
        let standaloneApps = policy.standaloneApps
            .filter { fileManager.fileExists(atPath: $0) }
            .map { URL(fileURLWithPath: $0) }

        return standaloneApps + policy.standardFolders.flatMap { folder in
            let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: folder),
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            return (enumerator?.allObjects ?? [])
                .compactMap { $0 as? URL }
                .filter { $0.pathExtension.lowercased() == "app" }
        }
    }
}
