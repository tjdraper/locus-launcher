import Foundation
import Testing

struct SpotlightHotKeysTests {
    @Test
    func missingEntriesUseApplesDefaults() {
        // Arrange
        let hotKeys = SpotlightHotKeys(symbolicHotKeys: [:])

        // Act
        let entries = hotKeys.entries

        // Assert
        #expect(entries == [
            .init(id: "64", isEnabled: true, keyCode: 49, modifierFlags: 1_048_576),
            .init(id: "65", isEnabled: true, keyCode: 49, modifierFlags: 1_572_864),
        ])
    }

    @Test
    func readsTheUsersOwnShortcut() {
        // Arrange
        let hotKeys = SpotlightHotKeys(symbolicHotKeys: ["64": entry(enabled: false, modifierFlags: 262_144)])

        // Act
        let spotlight = hotKeys.entries.first { $0.id == "64" }

        // Assert
        #expect(spotlight == .init(id: "64", isEnabled: false, keyCode: 49, modifierFlags: 262_144))
    }

    @Test
    func turningOffAMissingEntryWritesTheDefaultKeys() {
        // Arrange
        let hotKeys = SpotlightHotKeys(symbolicHotKeys: [:])

        // Act
        let changed = hotKeys.settingEnabled(false, for: ["64"])

        // Assert
        #expect(changed.entries.first { $0.id == "64" } == .init(id: "64", isEnabled: false, keyCode: 49, modifierFlags: 1_048_576))
        #expect(changed.symbolicHotKeys["65"] == nil)
    }

    @Test
    func changingAnEntryKeepsOtherShortcutsUntouched() {
        // Arrange
        let hotKeys = SpotlightHotKeys(symbolicHotKeys: ["7": entry(enabled: true, modifierFlags: 0), "64": entry(enabled: true)])

        // Act
        let changed = hotKeys.settingEnabled(false, for: ["64"])

        // Assert
        #expect((changed.symbolicHotKeys["7"] as? [String: Any])?["enabled"] as? Bool == true)
        #expect(changed.entries.first { $0.id == "64" }?.isEnabled == false)
    }

    @Test
    func skipsAnEntryInAnUnknownFormat() {
        // Arrange
        let hotKeys = SpotlightHotKeys(symbolicHotKeys: ["64": ["enabled": true, "value": ["parameters": [49]]]])

        // Act
        let ids = hotKeys.entries.map(\.id)

        // Assert
        #expect(ids == ["65"])
    }

    private func entry(enabled: Bool, modifierFlags: Int = 1_048_576) -> [String: Any] {
        ["enabled": enabled, "value": ["parameters": [32, 49, modifierFlags], "type": "standard"]]
    }
}
