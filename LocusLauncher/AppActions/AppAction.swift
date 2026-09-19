import AppKit

/// What the actions menu offers for an app. Each action's shortcut also works from the panel
/// without opening the menu.
nonisolated enum AppAction: CaseIterable, Sendable {
    case open
    case newWindow
    case revealInFinder
    case manageShortcuts
    case hide

    enum Key: Equatable, Sendable {
        case returnKey
        case delete
        case letter(Character)
    }

    var title: String {
        switch self {
        case .open: "Open"
        case .newWindow: "New Window"
        case .revealInFinder: "Reveal in Finder"
        case .manageShortcuts: "Manage Hot Keys…"
        case .hide: "Hide from Launcher"
        }
    }

    var key: Key {
        switch self {
        case .open, .newWindow, .revealInFinder: .returnKey
        case .manageShortcuts: .letter("k")
        case .hide: .delete
        }
    }

    var modifiers: NSEvent.ModifierFlags {
        switch self {
        case .open: []
        case .newWindow: [.command, .option]
        case .revealInFinder, .manageShortcuts: .command
        case .hide: [.command, .option]
        }
    }

    /// In the order and symbols macOS menus use.
    var shortcutSymbols: String {
        let modifierSymbols: [(NSEvent.ModifierFlags, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        let keySymbol = switch key {
        case .returnKey: "↩"
        case .delete: "⌫"
        case let .letter(letter): letter.uppercased()
        }
        return modifierSymbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + keySymbol
    }

    /// Takes the key event's `charactersIgnoringModifiers`, since menus match letter shortcuts by
    /// the character the key types in the current layout.
    init?(keyCode: UInt16, characters: String?, modifierFlags: NSEvent.ModifierFlags) {
        guard let key = Self.key(forKeyCode: keyCode, characters: characters) else { return nil }
        let modifiers = modifierFlags.intersection([.command, .option, .control, .shift])
        guard let action = Self.allCases.first(where: { $0.key == key && $0.modifiers == modifiers }) else {
            return nil
        }
        self = action
    }

    static func key(forKeyCode keyCode: UInt16, characters: String?) -> Key? {
        switch keyCode {
        case returnKeyCode, keypadEnterKeyCode: return .returnKey
        case deleteKeyCode: return .delete
        default:
            guard let characters, characters.count == 1, let letter = characters.lowercased().first, letter.isLetter else {
                return nil
            }
            return .letter(letter)
        }
    }

    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76
    private static let deleteKeyCode: UInt16 = 51
}
