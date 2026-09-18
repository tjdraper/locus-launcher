import AppKit

/// The menu bar draws a `MenuBarExtra` label as a single flat image and drops SwiftUI overlays,
/// so the update badge is drawn into the image itself.
enum MenuBarIcon {
    private static let symbolName = "square.grid.2x2"
    private static let badgeDiameter: CGFloat = 6
    /// Clear space cut around the badge so it reads as separate from the grid.
    private static let badgeGap: CGFloat = 1.5

    static func image(badged: Bool) -> NSImage {
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Locus Launcher") else {
            return NSImage()
        }
        guard badged else { return symbol }

        // A template image can't hold a red badge, so the grid is tinted by hand. The handler runs
        // at draw time under the menu bar's appearance, which lets the label color follow light
        // and dark menu bars.
        let badgedImage = NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect)
            NSColor.labelColor.setFill()
            rect.fill(using: .sourceIn)
            let badge = NSRect(
                x: rect.maxX - badgeDiameter,
                y: rect.maxY - badgeDiameter,
                width: badgeDiameter,
                height: badgeDiameter
            )
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: badge.insetBy(dx: -badgeGap, dy: -badgeGap)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: badge).fill()
            return true
        }
        badgedImage.accessibilityDescription = "Locus Launcher, update available"
        return badgedImage
    }
}
