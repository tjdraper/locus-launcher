import AppKit

/// The app icon's tiles and lens as one-color line art. Coordinates are on the app icon's
/// 1024-point canvas (`Icons/GenerateIconArt.swift` and the icon's `magnifier.svg`), so the two
/// stay recognizably the same.
enum MenuBarGlyph {
    private static let tileOrigins = [
        CGPoint(x: 124, y: 385), CGPoint(x: 384, y: 385),
        CGPoint(x: 124, y: 645), CGPoint(x: 384, y: 645),
    ]
    private static let tileSize: CGFloat = 220
    private static let tileRadius: CGFloat = 55
    private static let tileLineWidth: CGFloat = 58

    private static let lensCenter = CGPoint(x: 579, y: 415)
    private static let lensRadius: CGFloat = 222
    /// Thinner than the app icon's ring, which looks bold next to SF Symbols in the menu bar.
    private static let ringWidth: CGFloat = 86
    private static let handleStart = CGPoint(x: 742, y: 578)
    private static let handleEnd = CGPoint(x: 844, y: 680)
    private static let handleWidth: CGFloat = 100
    /// Clear space that separates the lens from the tiles under it.
    private static let lensGap: CGFloat = 44
    private static let magnification: CGFloat = 1.3

    private static let glyphCenter = CGPoint(x: 512, y: 503)
    private static let glyphSpan: CGFloat = 780

    /// Expects a flipped context, since the icon canvas has a top-left origin.
    static func draw(in context: CGContext, rect: CGRect, color: NSColor) {
        context.saveGState()
        defer { context.restoreGState() }

        let scale = min(rect.width, rect.height) / glyphSpan
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -glyphCenter.x, y: -glyphCenter.y)
        color.setFill()
        color.setStroke()
        context.setLineCap(.round)

        strokeTiles(in: context)

        context.setBlendMode(.clear)
        context.fillEllipse(in: lensRect(radius: lensRadius + ringWidth / 2 + lensGap))
        strokeHandle(in: context, width: handleWidth + lensGap * 2)
        context.setBlendMode(.normal)

        context.saveGState()
        context.addEllipse(in: lensRect(radius: lensRadius - ringWidth / 2 - lensGap))
        context.clip()
        context.translateBy(x: lensCenter.x, y: lensCenter.y)
        context.scaleBy(x: magnification, y: magnification)
        context.translateBy(x: -lensCenter.x, y: -lensCenter.y)
        strokeTiles(in: context)
        context.restoreGState()

        context.setLineWidth(ringWidth)
        context.strokeEllipse(in: lensRect(radius: lensRadius))
        strokeHandle(in: context, width: handleWidth)
    }

    private static func strokeTiles(in context: CGContext) {
        let inset = tileLineWidth / 2
        context.setLineWidth(tileLineWidth)
        for origin in tileOrigins {
            let tile = CGRect(origin: origin, size: CGSize(width: tileSize, height: tileSize))
                .insetBy(dx: inset, dy: inset)
            let radius = tileRadius - inset
            context.addPath(CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil))
        }
        context.strokePath()
    }

    private static func strokeHandle(in context: CGContext, width: CGFloat) {
        context.setLineWidth(width)
        context.strokeLineSegments(between: [handleStart, handleEnd])
    }

    private static func lensRect(radius: CGFloat) -> CGRect {
        CGRect(x: lensCenter.x - radius, y: lensCenter.y - radius, width: radius * 2, height: radius * 2)
    }
}
