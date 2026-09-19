import Foundation
import Testing

struct AppShortcutListTests {
    private let safari = IndexedApp(
        url: URL(fileURLWithPath: "/Applications/Safari.app"),
        name: "Safari",
        bundleIdentifier: "com.apple.Safari"
    )
    private let tool = IndexedApp(url: URL(fileURLWithPath: "/Users/test/Tool.app"), name: "Tool", bundleIdentifier: nil)
    private let keysS = AppShortcutList.Keys(carbonKeyCode: 1, carbonModifiers: 4352)
    private let keysW = AppShortcutList.Keys(carbonKeyCode: 13, carbonModifiers: 4352)

    @Test
    func givesAnAppAnyNumberOfHotKeys() {
        // Arrange
        var list = AppShortcutList()
        let open = list.add(for: safari)
        let newWindow = list.add(for: safari)

        // Act
        list.setKeys(keysS, for: open)
        list.setKeys(keysW, for: newWindow)
        list.setAction(.newWindow, for: newWindow)

        // Assert
        let entries = list.entries(forAppID: "com.apple.safari")
        #expect(entries.map(\.keys) == [keysS, keysW])
        #expect(entries.map(\.action) == [.open, .newWindow])
    }

    @Test
    func refusesKeysAnotherHotKeyUses() {
        // Arrange
        var list = AppShortcutList()
        let first = list.add(for: safari)
        let second = list.add(for: tool)
        list.setKeys(keysS, for: first)

        // Act
        list.setKeys(keysS, for: second)

        // Assert
        #expect(list.entry(using: keysS)?.id == first)
        #expect(list.entry(using: keysS, except: first) == nil)
        #expect(list.entries(forAppID: tool.persistentID).first?.keys == nil)
    }

    @Test
    func takesKeysFromAnotherAppsHotKeyAndRemovesIt() {
        // Arrange
        var list = AppShortcutList()
        let toolEntry = list.add(for: tool)
        list.setKeys(keysS, for: toolEntry)
        let safariEntry = list.add(for: safari)

        // Act
        list.takeKeys(keysS, for: safariEntry)

        // Assert
        #expect(list.entries.map(\.id) == [safariEntry])
        #expect(list.entry(using: keysS)?.id == safariEntry)
    }

    @Test
    func takesKeysFromTheSameAppsHotKeyAndKeepsItEmpty() {
        // Arrange
        var list = AppShortcutList()
        let first = list.add(for: safari)
        list.setKeys(keysS, for: first)
        let second = list.add(for: safari)

        // Act
        list.takeKeys(keysS, for: second)

        // Assert
        #expect(list.entries.map(\.keys) == [nil, keysS])
    }

    @Test
    func leavesRecordedHotKeysWhenDroppingUnrecordedOnes() {
        // Arrange
        var list = AppShortcutList()
        let recorded = list.add(for: safari)
        list.setKeys(keysS, for: recorded)
        list.add(for: safari)
        list.add(for: tool)

        // Act
        list.removeUnrecorded(forAppID: safari.persistentID)

        // Assert
        #expect(list.entries.count == 2)
        #expect(list.recordedEntriesByAppID.keys.sorted() == [safari.persistentID])
    }

    @Test
    func removesEveryHotKeyForOneApp() {
        // Arrange
        var list = AppShortcutList()
        list.add(for: safari)
        list.add(for: safari)
        let toolEntry = list.add(for: tool)

        // Act
        list.removeAll(forAppID: safari.persistentID)

        // Assert
        #expect(list.entries.map(\.id) == [toolEntry])
    }

    @Test
    func syncsOnlyAppsOtherMacsCanRecognize() {
        // Arrange
        var list = AppShortcutList()
        let safariEntry = list.add(for: safari)
        let toolEntry = list.add(for: tool)

        // Act
        list.setSyncsToOtherMacs(true, for: toolEntry)
        list.setSyncsToOtherMacs(false, for: safariEntry)

        // Assert
        #expect(list.entries.map(\.syncsToOtherMacs) == [false, false])
        #expect(list.entries.map(\.canSync) == [true, false])
    }
}
