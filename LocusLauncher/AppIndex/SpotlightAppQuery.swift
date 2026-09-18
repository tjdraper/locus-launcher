import Foundation

/// A live Spotlight search for every app bundle on the Mac's local volumes. Spotlight keeps it up
/// to date as apps are installed, removed, or on drives that mount and unmount.
final class SpotlightAppQuery {
    private let query = NSMetadataQuery()
    private var observations: [Task<Void, Never>] = []

    func start(onChange: @escaping ([URL]) -> Void) {
        query.predicate = NSPredicate(
            format: "%K == %@",
            NSMetadataItemContentTypeKey,
            "com.apple.application-bundle"
        )
        query.searchScopes = [NSMetadataQueryLocalComputerScope]

        let names: [Notification.Name] = [.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate]
        let queryID = ObjectIdentifier(query)
        observations = names.map { name in
            Task { [weak self] in
                // Filtering by `object:` would send the non-Sendable query across the sequence.
                let senders = NotificationCenter.default.notifications(named: name)
                    .compactMap { ($0.object as AnyObject?).map(ObjectIdentifier.init) }
                for await sender in senders where sender == queryID {
                    guard let self else { return }
                    onChange(results())
                }
            }
        }
        query.start()
    }

    isolated deinit {
        query.stop()
        observations.forEach { $0.cancel() }
    }

    private func results() -> [URL] {
        query.disableUpdates()
        defer { query.enableUpdates() }
        return query.results.compactMap { result in
            ((result as? NSMetadataItem)?.value(forAttribute: NSMetadataItemPathKey) as? String)
                .map { URL(fileURLWithPath: $0) }
        }
    }
}
