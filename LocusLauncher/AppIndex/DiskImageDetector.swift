import DiskArbitration
import Foundation

/// Answers whether a file lives on a mounted disk image, such as a downloaded installer DMG or a
/// simulator runtime. Remembers the answer per volume, so create one per indexing pass.
nonisolated final class DiskImageDetector {
    private let session = DASessionCreate(kCFAllocatorDefault)
    private var answers: [URL: Bool] = [:]

    func isOnDiskImage(_ url: URL) -> Bool {
        guard let volume = try? url.resourceValues(forKeys: [.volumeURLKey]).volume else {
            return false
        }
        if let answer = answers[volume] {
            return answer
        }
        let answer = isDiskImage(volume)
        answers[volume] = answer
        return answer
    }

    private func isDiskImage(_ volume: URL) -> Bool {
        guard let session,
              let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volume as CFURL),
              let description = DADiskCopyDescription(disk) as? [CFString: Any]
        else {
            return false
        }
        // Disk Arbitration has no flag for disk images. The disk images driver reports this model name.
        return description[kDADiskDescriptionDeviceModelKey] as? String == "Disk Image"
    }
}
