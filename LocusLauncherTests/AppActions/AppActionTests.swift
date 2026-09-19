import AppKit
import Testing

struct AppActionTests {
    @Test
    func matchesEachActionsShortcut() {
        // Arrange
        let keys: [(UInt16, NSEvent.ModifierFlags)] = [
            (36, []),
            (36, [.command, .option]),
            (36, .command),
            (51, [.command, .option]),
        ]

        // Act
        let actions = keys.map { AppAction(keyCode: $0.0, characters: nil, modifierFlags: $0.1) }

        // Assert
        #expect(actions == [.open, .newWindow, .revealInFinder, .hide])
    }

    @Test
    func ignoresDeviceFlagsAndTheKeypadEnter() {
        // Arrange
        let flags: NSEvent.ModifierFlags = [.command, .numericPad, .function]

        // Act
        let action = AppAction(keyCode: 76, characters: nil, modifierFlags: flags)

        // Assert
        #expect(action == .revealInFinder)
    }

    @Test
    func leavesOtherKeysToTheSearchField() {
        // Arrange
        let keys: [(UInt16, NSEvent.ModifierFlags)] = [
            (51, []),
            (51, .command),
            (36, .shift),
            (0, .command),
        ]

        // Act
        let actions = keys.map { AppAction(keyCode: $0.0, characters: nil, modifierFlags: $0.1) }

        // Assert
        #expect(actions.allSatisfy { $0 == nil })
    }

    @Test
    func matchesLetterShortcutsByTheCharacterTyped() {
        // Arrange
        struct KeyPress {
            let keyCode: UInt16
            let characters: String
            let modifiers: NSEvent.ModifierFlags
        }
        let keys = [
            KeyPress(keyCode: 40, characters: "k", modifiers: .command),
            // The key that types K on Dvorak.
            KeyPress(keyCode: 9, characters: "k", modifiers: .command),
            KeyPress(keyCode: 40, characters: "k", modifiers: []),
            KeyPress(keyCode: 40, characters: "K", modifiers: [.command, .shift]),
            KeyPress(keyCode: 40, characters: "j", modifiers: .command),
        ]

        // Act
        let actions = keys.map { AppAction(keyCode: $0.keyCode, characters: $0.characters, modifierFlags: $0.modifiers) }

        // Assert
        #expect(actions == [.manageShortcuts, .manageShortcuts, nil, nil, nil])
    }

    @Test
    func showsShortcutsTheWayMenusDo() {
        // Act
        let symbols = AppAction.allCases.map(\.shortcutSymbols)

        // Assert
        #expect(symbols == ["↩", "⌥⌘↩", "⌘↩", "⌘K", "⌥⌘⌫"])
    }
}
