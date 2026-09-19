import Foundation
import Testing

struct SyncMergeTests {
    private let safari = HiddenAppList.Entry(
        id: "com.apple.safari",
        name: "Safari",
        url: URL(fileURLWithPath: "/Applications/Safari.app"),
        syncsToOtherMacs: true
    )
    private let mail = HiddenAppList.Entry(
        id: "com.apple.mail",
        name: "Mail",
        url: URL(fileURLWithPath: "/System/Applications/Mail.app"),
        syncsToOtherMacs: true
    )

    @Test
    func sendsANewEntryToICloud() {
        // Arrange
        let merge = SyncMerge(local: [safari], cloud: [:], base: [:])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [safari])
        #expect(outcome.cloudWrites == [safari.id: safari])
        #expect(outcome.base == [safari.id: safari])
    }

    @Test
    func addsAnEntryFromAnotherMac() {
        // Arrange
        let merge = SyncMerge(local: [safari], cloud: [safari.id: safari, mail.id: mail], base: [safari.id: safari])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [safari, mail])
        #expect(outcome.cloudWrites.isEmpty)
        #expect(outcome.cloudRemovals.isEmpty)
    }

    @Test
    func removesAnEntryRemovedOnAnotherMac() {
        // Arrange
        let merge = SyncMerge(local: [safari, mail], cloud: [mail.id: mail], base: [safari.id: safari, mail.id: mail])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [mail])
        #expect(outcome.base == [mail.id: mail])
    }

    @Test
    func removesFromICloudAnEntryRemovedHere() {
        // Arrange
        let merge = SyncMerge(local: [mail], cloud: [safari.id: safari, mail.id: mail], base: [safari.id: safari, mail.id: mail])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [mail])
        #expect(outcome.cloudRemovals == [safari.id])
    }

    @Test
    func turningSyncOffKeepsTheEntryHereAndRemovesItElsewhere() {
        // Arrange
        var localOnly = safari
        localOnly.syncsToOtherMacs = false
        let merge = SyncMerge(local: [localOnly], cloud: [safari.id: safari], base: [safari.id: safari])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [localOnly])
        #expect(outcome.cloudRemovals == [safari.id])
        #expect(outcome.base.isEmpty)
    }

    @Test
    func leavesAnotherMacsEntryAloneWhenThisMacKeepsItsOwn() {
        // Arrange
        var localOnly = safari
        localOnly.syncsToOtherMacs = false
        let merge = SyncMerge(local: [localOnly], cloud: [safari.id: safari], base: [:])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [localOnly])
        #expect(outcome.cloudWrites.isEmpty)
        #expect(outcome.cloudRemovals.isEmpty)
    }

    @Test
    func sendsAChangeMadeHere() {
        // Arrange
        var renamed = safari
        renamed.name = "Safari Technology Preview"
        let merge = SyncMerge(local: [renamed], cloud: [safari.id: safari], base: [safari.id: safari])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [renamed])
        #expect(outcome.cloudWrites == [safari.id: renamed])
    }

    @Test
    func takesICloudsVersionWhenBothSidesChanged() {
        // Arrange
        var mine = safari
        mine.name = "Mine"
        var theirs = safari
        theirs.name = "Theirs"
        let merge = SyncMerge(local: [mine], cloud: [safari.id: theirs], base: [safari.id: safari])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [theirs])
        #expect(outcome.cloudWrites.isEmpty)
        #expect(outcome.base == [safari.id: theirs])
    }

    @Test
    func keepsAChangeMadeHereOverARemovalElsewhere() {
        // Arrange
        var renamed = safari
        renamed.name = "Renamed"
        let merge = SyncMerge(local: [renamed], cloud: [:], base: [safari.id: safari])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [renamed])
        #expect(outcome.cloudWrites == [safari.id: renamed])
    }

    @Test
    func mergesBothSidesWhenNothingWasAgreedYet() {
        // Arrange
        let merge = SyncMerge(local: [safari], cloud: [mail.id: mail], base: [:])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [safari, mail])
        #expect(outcome.cloudWrites == [safari.id: safari])
        #expect(outcome.cloudRemovals.isEmpty)
    }

    @Test
    func holdsBackAHotKeyUntilItHasKeys() {
        // Arrange
        let app = IndexedApp(url: URL(fileURLWithPath: "/Applications/Safari.app"), name: "Safari", bundleIdentifier: "com.apple.Safari")
        var list = AppShortcutList()
        list.add(for: app)
        let merge = SyncMerge(local: list.entries, cloud: [:], base: [:])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.cloudWrites.isEmpty)
        #expect(outcome.local == list.entries)
    }

    @Test
    func leavesOtherMacsHotKeyAloneWhileItsKeysAreBeingReRecorded() {
        // Arrange
        let synced = AppShortcutList.Entry(
            id: UUID(),
            appID: "com.apple.safari",
            appName: "Safari",
            keys: AppShortcutList.Keys(carbonKeyCode: 1, carbonModifiers: 4352),
            action: .open,
            syncsToOtherMacs: true
        )
        var recording = synced
        recording.keys = nil
        let merge = SyncMerge(local: [recording], cloud: [synced.syncID: synced], base: [synced.syncID: synced])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [recording])
        #expect(outcome.cloudRemovals.isEmpty)
        #expect(outcome.base == [synced.syncID: synced])
    }

    @Test
    func keepsAnotherMacsHiddenAppHiddenAfterThisMacUnhidesItsOwnCopy() {
        // Arrange
        let merge = SyncMerge(local: [HiddenAppList.Entry](), cloud: [safari.id: safari], base: [:])

        // Act
        let outcome = merge.run()

        // Assert
        #expect(outcome.local == [safari])
    }
}
