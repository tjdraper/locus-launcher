import AppKit

/// Puts the panel on the screen the pointer is on, centered horizontally and in the upper part of
/// the screen like Spotlight.
struct LauncherPanelPlacement {
    let size: NSSize

    func frame() -> NSRect? {
        let pointer = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) ?? NSScreen.main else {
            return nil
        }

        let visible = screen.visibleFrame
        let top = visible.maxY - visible.height * 0.2
        return NSRect(
            x: visible.midX - size.width / 2,
            y: max(visible.minY, top - size.height),
            width: size.width,
            height: size.height
        )
    }
}
