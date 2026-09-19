import CoreGraphics

/// Puts the hot key editor's top edge at the top of whatever opened it, centered across it, the way
/// a sheet drops from under a title bar, while keeping the editor on screen.
nonisolated struct AppShortcutEditorPlacement {
    let anchor: CGRect
    let visibleScreenFrame: CGRect

    func origin(for size: CGSize) -> CGPoint {
        let visible = visibleScreenFrame
        let x = anchor.midX - size.width / 2
        let y = anchor.maxY - size.height
        // Clamped so an editor bigger than the screen keeps its title bar and leading edge visible.
        return CGPoint(
            x: max(min(x, visible.maxX - size.width), visible.minX),
            y: min(max(y, visible.minY), visible.maxY - size.height)
        )
    }
}
