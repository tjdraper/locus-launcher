import Foundation
import Observation

/// The apps the launcher can open, kept current as apps are installed and removed.
@Observable
final class AppIndexStore {
    private(set) var apps: [IndexedApp] = []

    @ObservationIgnored private let policy = AppLocationPolicy.current
    @ObservationIgnored private let spotlight = SpotlightAppQuery()
    @ObservationIgnored private lazy var folderWatcher = AppFolderWatcher { [weak self] in
        self?.scheduleRebuild()
    }
    @ObservationIgnored private var spotlightResults: [URL] = []
    @ObservationIgnored private var rebuild: Task<Void, Never>?

    func start() {
        folderWatcher.start(folders: policy.standardFolders)
        spotlight.start { [weak self] results in
            self?.spotlightResults = results
            self?.scheduleRebuild()
        }
        // Spotlight's first results can take a while, so list the standard folders right away.
        scheduleRebuild()
    }

    /// An install or update fires a burst of file events, so they're coalesced into one rebuild.
    private func scheduleRebuild() {
        rebuild?.cancel()
        rebuild = Task { [policy, spotlightResults] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            let apps = await AppIndexBuilder(policy: policy).build(spotlightResults: spotlightResults)
            guard !Task.isCancelled else { return }
            self.apps = apps
        }
    }
}
