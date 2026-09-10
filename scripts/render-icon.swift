#!/usr/bin/env swift
// render-icon.swift — Quill app icon, Reminders-style with feather accent.
// Output:
//   ~/Desktop/Quill-icon.png              (1024 px @1x)
//   ~/Desktop/Quill-icon@2x.png           (1024 px @2x for retention preview)
//   ~/quill-ios/Quill/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// Uses a fixed-size NSImage + lockFocus on macOS 14 — bitmap behaves at 1x
// unless the host runs in a retina simulator, in which case we downscale at
// the end with `sips` to land on exactly 1024×1024.

import AppKit

let size = 1024
let brand      = NSColor(srgbRed: 0.475, green: 0.404, blue: 0.831, alpha: 1.0)
let brandDeep  = NSColor(srgbRed: 0.396, green: 0.318, blue: 0.737, alpha: 1.0)
let coral      = NSColor(srgbRed: 0.984, green: 0.412, blue: 0.310, alpha: 1.0)
let gold       = NSColor(srgbRed: 0.961, green: 0.745, blue: 0.255, alpha: 1.0)
let navy       = NSColor(srgbRed: 0.043, green: 0.055, blue: 0.071, alpha: 1.0)
let navyDeep   = NSColor(srgbRed: 0.020, green: 0.027, blue: 0.055, alpha: 1.0)
let paper      = NSColor(srgbRed: 0.984, green: 0.984, blue: 0.992, alpha: 1.0)
let paperSoft  = NSColor(srgbRed: 0.937, green: 0.945, blue: 0.961, alpha: 1.0)
let inkLine    = NSColor(srgbRed: 0.10,  green: 0.13,  blue: 0.20,  alpha: 0.22)
let inkLineDark = NSColor(srgbRed: 0.10, green: 0.13,  blue: 0.20,  alpha: 0.32)
let inkSoft    = NSColor(srgbRed: 0.10, green: 0.13,  blue: 0.20,  alpha: 0.55)

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let cg = NSGraphicsContext.current!.cgContext
cg.setAllowsAntialiasing(true)
cg.setShouldAntialias(true)

let rect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))

// Background gradient + corner glow
NSGradient(colors: [navy, navyDeep])!.draw(in: rect, angle: 270)

if let srgbSpace = NSColorSpace.sRGB.cgColorSpace,
   let glow = CGGradient(
        colorsSpace: srgbSpace,
        colors: [brand.withAlphaComponent(0.32).cgColor,
                 brand.withAlphaComponent(0.0).cgColor] as CFArray,
        locations: [0, 1]) {
    cg.saveGState()
    cg.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 800, y: 824),
        startRadius: 0,
        endCenter: CGPoint(x: 800, y: 824),
        endRadius: 520,
        options: CGGradientDrawingOptions.drawsBeforeStartLocation
    )
    cg.restoreGState()
}

// Card — white rounded square in the center
let cardSize: CGFloat = 720
let cardX = (CGFloat(size) - cardSize) / 2
let cardY = (CGFloat(size) - cardSize) / 2
let card = NSBezierPath(roundedRect: NSRect(x: cardX, y: cardY, width: cardSize, height: cardSize),
                        xRadius: 96, yRadius: 96)
let shadow = NSShadow()
shadow.shadowOffset = NSSize(width: 0, height: 8)
shadow.shadowBlurRadius = 36
shadow.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.30)
shadow.set()
paper.setFill()
card.fill()

// Subtle vertical gradient on the card
NSGraphicsContext.saveGraphicsState()
card.addClip()
NSGradient(colors: [paper, paperSoft])!.draw(in: card.bounds, angle: 270)
NSGraphicsContext.restoreGraphicsState()

NSColor(white: 0, alpha: 0.05).setStroke()
card.lineWidth = 1
card.stroke()

// Header text — "Quill"
NSAttributedString(string: "Quill", attributes: [
    .font: NSFont.boldSystemFont(ofSize: 64),
    .foregroundColor: brandDeep
]).draw(at: NSPoint(x: cardX + 64, y: cardY + cardSize - 100))

NSAttributedString(string: "READING QUEUE", attributes: [
    .font: NSFont.systemFont(ofSize: 22, weight: .heavy),
    .kern: 2.2,
    .foregroundColor: inkSoft
]).draw(at: NSPoint(x: cardX + 64, y: cardY + cardSize - 144))

// Article rows (avatar + label + progress bar)
let palette: [NSColor] = [brand, coral, gold, brandDeep]
let widths: [CGFloat]   = [0.82, 0.58, 0.72, 0.46]
let labels: [String]   = ["Linus", "Apple", "Brandur", "Tailscale"]
let metas:  [String]   = ["Monitors are easy", "Newsroom", "Rampant", "A year in review"]
let rowCount = 4
let rowAreaTop = cardY + cardSize - 210
let rowAreaBottom = cardY + 220
let rowSpacing = (rowAreaTop - rowAreaBottom) / CGFloat(rowCount)
let rowLeftX = cardX + 64

for i in 0..<rowCount {
    let y = rowAreaTop - CGFloat(i) * rowSpacing - rowSpacing / 2
    let avatarRect = NSRect(x: rowLeftX, y: y - 28, width: 56, height: 56)

    palette[i].withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: avatarRect).fill()

    let dotRect = NSRect(x: avatarRect.midX - 10, y: avatarRect.midY - 10, width: 20, height: 20)
    palette[i].setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    let labelX = rowLeftX + 56 + 18
    NSAttributedString(string: labels[i], attributes: [
        .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
        .foregroundColor: inkLineDark
    ]).draw(at: NSPoint(x: labelX, y: y + 12))

    NSAttributedString(string: metas[i], attributes: [
        .font: NSFont.systemFont(ofSize: 18, weight: .regular),
        .foregroundColor: inkLine
    ]).draw(at: NSPoint(x: labelX, y: y - 14))

    let barArea = NSRect(x: labelX + 220, y: y - 4, width: 200, height: 8)
    NSColor(srgbRed: 0.93, green: 0.94, blue: 0.96, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: barArea, xRadius: 4, yRadius: 4).fill()
    palette[i].setFill()
    NSBezierPath(roundedRect: NSRect(x: barArea.minX, y: barArea.minY, width: barArea.width * widths[i], height: barArea.height),
                 xRadius: 4, yRadius: 4).fill()
}

// Feather accent — top-right corner of the card
cg.saveGState()
let featherAnchor = NSPoint(x: cardX + cardSize - 110, y: cardY + cardSize - 110)
cg.translateBy(x: featherAnchor.x, y: featherAnchor.y)
cg.rotate(by: -.pi / 4)

let featherLen: CGFloat = 110
let featherBody = NSBezierPath()
featherBody.move(to: NSPoint(x: -featherLen, y: 0))
featherBody.line(to: NSPoint(x: 0, y: featherLen * 0.5))
featherBody.curve(to: NSPoint(x: -featherLen, y: 0),
                  controlPoint1: NSPoint(x: -featherLen * 0.6, y: featherLen * 0.4),
                  controlPoint2: NSPoint(x: -featherLen * 0.6, y: featherLen * 0.08))
featherBody.close()
NSGradient(colors: [brand, brandDeep])!.draw(in: featherBody, angle: 270)

NSColor(white: 1, alpha: 0.55).setFill()
NSBezierPath(roundedRect: NSRect(x: -featherLen + 10, y: featherLen * 0.30, width: featherLen - 25, height: 4),
             xRadius: 2, yRadius: 2).fill()

coral.setFill()
NSBezierPath(ovalIn: NSRect(x: -8, y: featherLen * 0.5 - 8, width: 16, height: 16)).fill()

cg.restoreGState()

img.unlockFocus()

// Encode
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [.compressionFactor: 0.95]) else {
    FileHandle.standardError.write("PNG encoding failed\n".data(using: .utf8)!)
    exit(1)
}

let targets = [
    "/Users/enriquevaleros/Desktop/Quill-icon.png",
    "/Users/enriquevaleros/quill-ios/Quill/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
]
for path in targets {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
    do {
        try png.write(to: url)
        print("✓ \(path) (\(png.count / 1024) KB)")
    } catch {
        print("✗ \(path): \(error)")
    }
}

// Force 1024×1024 with sips (NSImage on a retina device can come back at 2x).
for path in targets {
    let sips = Process()
    sips.launchPath = "/usr/bin/sips"
    sips.arguments = ["-z", "1024", "1024", path]
    sips.standardOutput = FileHandle.nullDevice
    sips.standardError = FileHandle.nullDevice
    try? sips.run()
    sips.waitUntilExit()
}

// 512@2x preview (visually the same content, smaller file)
let previewSips = Process()
previewSips.launchPath = "/usr/bin/sips"
previewSips.arguments = ["-z", "512", "512",
                          "/Users/enriquevaleros/Desktop/Quill-icon.png",
                          "--out", "/Users/enriquevaleros/Desktop/Quill-icon@2x.png"]
previewSips.standardOutput = FileHandle.nullDevice
previewSips.standardError = FileHandle.nullDevice
try? previewSips.run()
previewSips.waitUntilExit()

print("\n🎉 Quill icon rendered at 1024×1024.")
