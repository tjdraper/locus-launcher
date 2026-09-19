import AppKit

/// The menu bar draws a `MenuBarExtra` label as a single flat image and drops SwiftUI overlays,
/// so the update badge is drawn into the image itself.
enum MenuBarIcon {
    private static let size = NSSize(width: 18, height: 18)
    private static let badgeDiameter: CGFloat = 6
    /// Clear space cut around the badge so it reads as separate from the glyph.
    private static let badgeGap: CGFloat = 1.5

    static func image(badged: Bool) -> NSImage {
        // The handler runs at draw time under the menu bar's appearance, which lets the label
        // color follow light and dark menu bars when the image can't be a template.
        let image = NSImage(size: size, flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            MenuBarGlyph.draw(in: context, rect: rect, color: .labelColor)
            if badged {
                drawBadge(in: context)
            }
            return true
        }
        // A template image can't hold a red badge, so the badged icon is tinted by hand.
        image.isTemplate = !badged
        image.accessibilityDescription = badged ? "Locus Launcher, update available" : "Locus Launcher"
        return image
    }

    /// Top-left, because the lens fills the top-right corner.
    private static func drawBadge(in context: CGContext) {
        let badge = CGRect(x: 0, y: 0, width: badgeDiameter, height: badgeDiameter)
        context.setBlendMode(.clear)
        context.fillEllipse(in: badge.insetBy(dx: -badgeGap, dy: -badgeGap))
        context.setBlendMode(.normal)
        NSColor.systemRed.setFill()
        context.fillEllipse(in: badge)
    }
}
