import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Cmd+Space belongs to Spotlight until the user turns Spotlight's shortcut off, so the
    /// launcher only receives it after that.
    static let toggleLauncher = Self("toggleLauncher", initial: .init(.space, modifiers: .command))
}
