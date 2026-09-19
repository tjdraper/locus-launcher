import CoreGraphics

/// Puts the hot key editor's top edge at the top of whatever opened it, centered across it, the way
/// a sheet drops from under a title bar, while keeping the editor on screen.
nonisolated struct AppShortcutEditorPlacement {
    /// How far an editor steps down and to the right when an open one already sits where it would go.
    private static let cascadeStep: CGFloat = 24
    private static let cascadeLimit = 8

    let anchor: CGRect
    let visibleScreenFrame: CGRect

    /// Editors that are already open are given as their frames, since they differ in height and it
    /// is their top-left corners that line up.
    func origin(for size: CGSize, avoiding taken: [CGRect] = []) -> CGPoint {
        let takenCorners = taken.map { CGPoint(x: $0.minX, y: $0.maxY) }
        var origin = onScreen(CGPoint(x: anchor.midX - size.width / 2, y: anchor.maxY - size.height), size: size)
        var steps = 0
        while takenCorners.contains(where: { $0.equalTo(CGPoint(x: origin.x, y: origin.y + size.height)) }),
              steps < Self.cascadeLimit {
            steps += 1
            let stepped = CGPoint(x: origin.x + Self.cascadeStep, y: origin.y - Self.cascadeStep)
            origin = onScreen(stepped, size: size)
        }
        return origin
    }

    /// Keeps an editor bigger than the screen showing its title bar and leading edge.
    private func onScreen(_ origin: CGPoint, size: CGSize) -> CGPoint {
        let visible = visibleScreenFrame
        return CGPoint(
            x: max(min(origin.x, visible.maxX - size.width), visible.minX),
            y: min(max(origin.y, visible.minY), visible.maxY - size.height)
        )
    }
}
