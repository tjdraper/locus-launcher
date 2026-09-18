import AppKit
import KeyboardShortcuts

/// Tracks whether Spotlight holds the launcher's shortcut, or a shortcut the user may want for the
/// launcher, and turns Spotlight's shortcut off or back on for the user.
@Observable
final class SpotlightShortcutStore {
    /// Remembers which shortcuts this app turned off, so it only offers to turn back on what it
    /// changed and leaves the user's own choices alone.
    private static let turnedOffDefaultsKey = "SpotlightShortcutsTurnedOff"

    private let spotlightSwitch = SpotlightShortcutSwitch()

    private(set) var conflictingShortcuts: [SpotlightHotKeys.Entry] = []
    /// Spotlight's own shortcut while it's on and not already the launcher's. It has to be off
    /// before the recorder can capture it, since Spotlight takes the keys first.
    private(set) var spotlightSearchShortcut: SpotlightHotKeys.Entry?
    private(set) var shortcutsTurnedOffByApp: [SpotlightHotKeys.Entry] = []
    private(set) var isChanging = false
    private(set) var changeFailed = false

    private var turnedOffIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: Self.turnedOffDefaultsKey) ?? []) }
        set { UserDefaults.standard.set(newValue.sorted(), forKey: Self.turnedOffDefaultsKey) }
    }

    func refresh() {
        let entries = spotlightSwitch.read().entries
        let launcherShortcut = KeyboardShortcuts.getShortcut(for: .toggleLauncher)
        conflictingShortcuts = entries.filter { $0.isEnabled && Self.shortcut(for: $0) == launcherShortcut }
        spotlightSearchShortcut = entries.first {
            $0.id == SpotlightHotKeys.showSpotlightSearchID && $0.isEnabled && !conflictingShortcuts.contains($0)
        }

        // An entry that's on again was turned back on in System Settings, so it's no longer this
        // app's to restore.
        let stillOff = turnedOffIDs.filter { id in entries.contains { $0.id == id && !$0.isEnabled } }
        turnedOffIDs = stillOff
        shortcutsTurnedOffByApp = entries.filter { stillOff.contains($0.id) }
    }

    func turnOffConflictingShortcuts() async {
        await turnOff(conflictingShortcuts)
    }

    func turnOffSpotlightSearchShortcut() async {
        await turnOff(spotlightSearchShortcut.map { [$0] } ?? [])
    }

    func turnShortcutsBackOn() async {
        await change(turnedOffIDs, toEnabled: true)
    }

    func openKeyboardSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    static func shortcut(for entry: SpotlightHotKeys.Entry) -> KeyboardShortcuts.Shortcut {
        KeyboardShortcuts.Shortcut(
            KeyboardShortcuts.Key(rawValue: entry.keyCode),
            modifiers: NSEvent.ModifierFlags(rawValue: entry.modifierFlags)
        )
    }

    static func displayNames(of entries: [SpotlightHotKeys.Entry]) -> String {
        entries.map { shortcut(for: $0).description }.formatted(.list(type: .and))
    }

    private func turnOff(_ entries: [SpotlightHotKeys.Entry]) async {
        let ids = Set(entries.map(\.id))
        // Recorded before the change, because a change that fails to apply may still have been
        // saved. The refresh drops whatever didn't end up off.
        turnedOffIDs.formUnion(ids)
        await change(ids, toEnabled: false)
    }

    private func change(_ ids: Set<String>, toEnabled isEnabled: Bool) async {
        isChanging = true
        do {
            try await spotlightSwitch.setEnabled(isEnabled, for: ids)
            changeFailed = false
        } catch {
            changeFailed = true
        }
        isChanging = false
        refresh()
    }
}
