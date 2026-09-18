import Foundation

/// Spotlight's keyboard shortcuts as macOS stores them in the `AppleSymbolicHotKeys` dictionary
/// of `com.apple.symbolichotkeys`. The format is undocumented, so it needs checking on each macOS
/// release.
nonisolated struct SpotlightHotKeys {
    struct Entry: Equatable {
        let id: String
        let isEnabled: Bool
        let keyCode: Int
        /// `NSEvent.ModifierFlags` raw value.
        let modifierFlags: UInt
    }

    static let showSpotlightSearchID = "64"
    static let showFinderSearchWindowID = "65"
    static let ids = [showSpotlightSearchID, showFinderSearchWindowID]

    /// macOS leaves an entry out until the user first changes it, and a missing entry means the
    /// shortcut is on with Apple's default keys (Cmd+Space and Cmd+Option+Space).
    private static var defaultEntries: [String: [String: Any]] {
        [
            "64": ["enabled": true, "value": ["parameters": [32, 49, 1_048_576], "type": "standard"]],
            "65": ["enabled": true, "value": ["parameters": [65_535, 49, 1_572_864], "type": "standard"]],
        ]
    }

    private(set) var symbolicHotKeys: [String: Any]

    init(symbolicHotKeys: [String: Any]) {
        self.symbolicHotKeys = symbolicHotKeys
    }

    var entries: [Entry] {
        Self.ids.compactMap(entry)
    }

    func settingEnabled(_ isEnabled: Bool, for ids: Set<String>) -> Self {
        var copy = self
        for id in ids {
            guard var entry = rawEntry(for: id) else { continue }
            entry["enabled"] = isEnabled
            copy.symbolicHotKeys[id] = entry
        }
        return copy
    }

    private func rawEntry(for id: String) -> [String: Any]? {
        symbolicHotKeys[id] as? [String: Any] ?? Self.defaultEntries[id]
    }

    private func entry(for id: String) -> Entry? {
        guard
            let raw = rawEntry(for: id),
            let isEnabled = raw["enabled"] as? NSNumber,
            let value = raw["value"] as? [String: Any],
            let parameters = value["parameters"] as? [NSNumber],
            parameters.count == 3
        else {
            return nil
        }
        return Entry(
            id: id,
            isEnabled: isEnabled.boolValue,
            keyCode: parameters[1].intValue,
            modifierFlags: parameters[2].uintValue
        )
    }
}
