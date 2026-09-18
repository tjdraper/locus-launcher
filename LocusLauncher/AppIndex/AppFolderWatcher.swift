import CoreServices
import Foundation

/// Reports changes anywhere inside the standard app folders. Spotlight covers these folders too,
/// but only while indexing is on, and it can take several seconds to notice.
final class AppFolderWatcher {
    private let onChange: () -> Void
    private var stream: FSEventStreamRef?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func start(folders: [String]) {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, info, _, _, _, _ in
                guard let info else { return }
                // The stream is scheduled on the main queue below.
                MainActor.assumeIsolated {
                    Unmanaged<AppFolderWatcher>.fromOpaque(info).takeUnretainedValue().onChange()
                }
            },
            &context,
            folders as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
        ) else {
            return
        }

        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    /// The stream holds an unretained pointer to this watcher, so it has to be torn down first.
    isolated deinit {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}
