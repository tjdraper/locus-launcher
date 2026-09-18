import AppKit

/// What the actions menu offers for an app. Each action's shortcut also works from the panel
/// without opening the menu.
nonisolated enum AppAction: CaseIterable, Sendable {
    case open
    case newWindow
    case revealInFinder
    case hide

    enum Key: Sendable {
        case returnKey
        case delete
    }

    var title: String {
        switch self {
        case .open: "Open"
        case .newWindow: "New Window"
        case .revealInFinder: "Reveal in Finder"
        case .hide: "Hide from Launcher"
        }
    }

    var key: Key {
        switch self {
        case .open, .newWindow, .revealInFinder: .returnKey
        case .hide: .delete
        }
    }

    var modifiers: NSEvent.ModifierFlags {
        switch self {
        case .open: []
        case .newWindow: [.command, .option]
        case .revealInFinder: .command
        case .hide: [.command, .option]
        }
    }

    /// In the order and symbols macOS menus use.
    var shortcutSymbols: String {
        let modifierSymbols: [(NSEvent.ModifierFlags, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        let keySymbol = switch key {
        case .returnKey: "↩"
        case .delete: "⌫"
        }
        return modifierSymbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + keySymbol
    }

    init?(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        guard let key = Self.key(forKeyCode: keyCode) else { return nil }
        let modifiers = modifierFlags.intersection([.command, .option, .control, .shift])
        guard let action = Self.allCases.first(where: { $0.key == key && $0.modifiers == modifiers }) else {
            return nil
        }
        self = action
    }

    static func key(forKeyCode keyCode: UInt16) -> Key? {
        switch keyCode {
        case returnKeyCode, keypadEnterKeyCode: .returnKey
        case deleteKeyCode: .delete
        default: nil
        }
    }

    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76
    private static let deleteKeyCode: UInt16 = 51
}
