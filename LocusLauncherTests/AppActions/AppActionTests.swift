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
        let actions = keys.map { AppAction(keyCode: $0.0, modifierFlags: $0.1) }

        // Assert
        #expect(actions == [.open, .newWindow, .revealInFinder, .hide])
    }

    @Test
    func ignoresDeviceFlagsAndTheKeypadEnter() {
        // Arrange
        let flags: NSEvent.ModifierFlags = [.command, .numericPad, .function]

        // Act
        let action = AppAction(keyCode: 76, modifierFlags: flags)

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
        let actions = keys.map { AppAction(keyCode: $0.0, modifierFlags: $0.1) }

        // Assert
        #expect(actions.allSatisfy { $0 == nil })
    }

    @Test
    func showsShortcutsTheWayMenusDo() {
        // Act
        let symbols = AppAction.allCases.map(\.shortcutSymbols)

        // Assert
        #expect(symbols == ["↩", "⌥⌘↩", "⌘↩", "⌥⌘⌫"])
    }
}
