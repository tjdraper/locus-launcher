import Foundation

/// Decides what a Right arrow press in the launcher panel does: move the search field's cursor, or
/// open the selected row's actions menu.
///
/// The press that carries the cursor to the end of the text only moves it, and so does every repeat
/// while the key stays down. Letting go starts a short wait, so a run of presses that ends at the
/// end of the text doesn't open the menu on the press right after it either.
nonisolated struct RightArrowMenuGate {
    /// Short enough that a deliberate second press feels immediate, long enough to swallow one more
    /// press from a fast run through the text.
    static let settleDelay: TimeInterval = 0.4

    private var isMovingCursor = false
    private var openingBlockedUntil = -TimeInterval.infinity

    mutating func pressOpensActionsMenu(cursorIsAtEnd: Bool, at time: TimeInterval) -> Bool {
        guard cursorIsAtEnd else {
            isMovingCursor = true
            return false
        }
        return !isMovingCursor && time >= openingBlockedUntil
    }

    mutating func keyReleased(at time: TimeInterval) {
        isMovingCursor = false
        openingBlockedUntil = time + Self.settleDelay
    }
}
