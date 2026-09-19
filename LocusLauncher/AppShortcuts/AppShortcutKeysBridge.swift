import KeyboardShortcuts

/// The list stores its own key type so it doesn't depend on the KeyboardShortcuts package, which
/// the tests don't link.
extension AppShortcutList.Keys {
    init(_ shortcut: KeyboardShortcuts.Shortcut) {
        self.init(carbonKeyCode: shortcut.carbonKeyCode, carbonModifiers: shortcut.carbonModifiers)
    }

    var shortcut: KeyboardShortcuts.Shortcut {
        KeyboardShortcuts.Shortcut(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers)
    }

    /// In the order and symbols macOS menus use.
    var symbols: String {
        shortcut.description
    }
}
