import Foundation
import Testing

struct RightArrowMenuGateTests {
    @Test
    func opensTheMenuWhenTheCursorIsAlreadyAtTheEnd() {
        // Arrange
        var gate = RightArrowMenuGate()

        // Act
        let opens = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1)

        // Assert
        #expect(opens)
    }

    @Test
    func movesTheCursorWhenThereIsTextToItsRight() {
        // Arrange
        var gate = RightArrowMenuGate()

        // Act
        let opens = gate.pressOpensActionsMenu(cursorIsAtEnd: false, at: 1)

        // Assert
        #expect(!opens)
    }

    @Test
    func keepsTheMenuClosedWhileTheKeyStaysDownAfterReachingTheEnd() {
        // Arrange
        var gate = RightArrowMenuGate()
        _ = gate.pressOpensActionsMenu(cursorIsAtEnd: false, at: 1)

        // Act
        let opens = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1.1)
        let opensOnTheNextRepeat = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1.2)

        // Assert
        #expect(!opens)
        #expect(!opensOnTheNextRepeat)
    }

    @Test
    func waitsOutTheSettleDelayAfterTheKeyIsReleased() {
        // Arrange
        var gate = RightArrowMenuGate()
        _ = gate.pressOpensActionsMenu(cursorIsAtEnd: false, at: 1)
        _ = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1.1)
        gate.keyReleased(at: 1.2)

        // Act
        let withinTheDelay = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1.2 + RightArrowMenuGate.settleDelay / 2)
        let afterTheDelay = gate.pressOpensActionsMenu(cursorIsAtEnd: true, at: 1.2 + RightArrowMenuGate.settleDelay)

        // Assert
        #expect(!withinTheDelay)
        #expect(afterTheDelay)
    }
}
