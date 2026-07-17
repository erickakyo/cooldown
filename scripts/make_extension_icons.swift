#!/usr/bin/env swift
// Generates PNG icons for the Cooldown Chrome Extension: rounded ice-blue gradient + snowflake.
// Usage: swift scripts/make_extension_icons.swift

import AppKit

let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath
let assetsDir = URL(fileURLWithPath: currentDir).appendingPathComponent("extension/assets", isDirectory: true)

// Create extension/assets if it doesn't exist
try? fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let inset = size * 0.05
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Blue-ice gradient matching the brand
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.15, green: 0.65, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.25, blue: 0.65, alpha: 1),
    ])!
    gradient.draw(in: path, angle: -60)

    func drawSymbol(_ name: String, pointSize: CGFloat, color: NSColor, dx: CGFloat, dy: CGFloat) {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        color.set()
        let bounds = NSRect(origin: .zero, size: symbol.size)
        symbol.draw(in: bounds)
        bounds.fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: NSRect(
            x: rect.midX - symbol.size.width / 2 + dx,
            y: rect.midY - symbol.size.height / 2 + dy,
            width: symbol.size.width,
            height: symbol.size.height
        ))
    }

    // Snowflake symbol
    drawSymbol("snowflake", pointSize: rect.width * 0.6, color: .white, dx: 0, dy: 0)

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, pixels: Int, name: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    let targetURL = assetsDir.appendingPathComponent(name)
    try! data.write(to: targetURL)
    print("Generated: \(name)")
}

let sizes = [16, 32, 48, 128]
for size in sizes {
    let img = drawIcon(size: CGFloat(size))
    savePNG(img, pixels: size, name: "icon\(size).png")
}

print("✅ Chrome Extension icons successfully generated in extension/assets/")
