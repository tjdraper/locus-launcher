import AppKit

// Single source of geometry: the real scene and the magnified copy inside the lens
// are drawn by the same code, so they can never drift apart.
let canvas = 1024
let lensCenter = CGPoint(x: 579, y: 415)
let lensRadius: CGFloat = 170
let magnification: CGFloat = 1.3

let bandHeight: CGFloat = 350
let tileSize: CGFloat = 220
let tileRadius: CGFloat = 55
let columns: [CGFloat] = [124, 384]
let rows: [CGFloat] = [385, 645]

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

let blue = rgb(74, 144, 217)
let green = rgb(61, 200, 114)
let orange = rgb(240, 112, 32)
let tileColors = [[blue, green], [green, orange]]

func context() -> CGContext {
    let ctx = CGContext(data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(canvas))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func write(_ ctx: CGContext, _ name: String) {
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: name))
}

func drawBackground(_ ctx: CGContext, field: CGColor, band: CGColor) {
    ctx.setFillColor(field)
    ctx.fill(CGRect(x: -2000, y: -2000, width: 5000, height: 5000))
    ctx.setFillColor(band)
    ctx.fill(CGRect(x: -2000, y: -2000, width: 5000, height: 2000 + bandHeight))
}

func drawTiles(_ ctx: CGContext) {
    for (rowIndex, y) in rows.enumerated() {
        for (columnIndex, x) in columns.enumerated() {
            ctx.setFillColor(tileColors[rowIndex][columnIndex])
            ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: tileSize, height: tileSize),
                               cornerWidth: tileRadius, cornerHeight: tileRadius, transform: nil))
            ctx.fillPath()
        }
    }
}

let lightField = rgb(224, 184, 122), lightBand = rgb(42, 98, 168)
let darkField = rgb(58, 30, 10), darkBand = rgb(24, 56, 98)

for (name, field, band) in [("background-light.png", lightField, lightBand),
                            ("background-dark.png", darkField, darkBand)] {
    let ctx = context()
    drawBackground(ctx, field: field, band: band)
    write(ctx, name)
}

let tiles = context()
drawTiles(tiles)
write(tiles, "app-tiles.png")

for (name, field, band) in [("lens-content-light.png", lightField, lightBand),
                            ("lens-content-dark.png", darkField, darkBand)] {
    let ctx = context()
    ctx.addArc(center: lensCenter, radius: lensRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.clip()
    ctx.translateBy(x: lensCenter.x, y: lensCenter.y)
    ctx.scaleBy(x: magnification, y: magnification)
    ctx.translateBy(x: -lensCenter.x, y: -lensCenter.y)
    drawBackground(ctx, field: field, band: band)
    drawTiles(ctx)
    write(ctx, name)
}

let gloss = context()
gloss.setFillColor(CGColor(gray: 1, alpha: 0.45))
gloss.saveGState()
gloss.translateBy(x: 570, y: 340)
gloss.rotate(by: .pi / 4)
gloss.addEllipse(in: CGRect(x: -130, y: -46, width: 260, height: 92))
gloss.fillPath()
gloss.restoreGState()
let blurred = CIImage(cgImage: gloss.makeImage()!)
    .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 26])
    .cropped(to: CGRect(x: 0, y: 0, width: canvas, height: canvas))
let glossOut = context()
glossOut.addArc(center: lensCenter, radius: lensRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
glossOut.clip()
glossOut.draw(CIContext().createCGImage(blurred, from: blurred.extent)!,
              in: CGRect(x: 0, y: 0, width: canvas, height: canvas))
write(glossOut, "lens-gloss.png")

// Run from the icon's Assets folder:
// swift ../../Icons/GenerateIconArt.swift
