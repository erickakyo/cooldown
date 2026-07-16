#!/usr/bin/env swift
// Gera o AppIcon.icns do Cooldown: gradiente arredondado + ampulheta.
// Uso: swift scripts/make_icon.swift <saida.icns>

import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"
let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("CooldownIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: tmpDir)
try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // macOS: o ícone ocupa ~80% do canvas com cantos arredondados
    let inset = size * 0.1
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Gradiente azul-gelo: "cooldown" = esfriar (trocadilho da marca)
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

    // Floco de neve branco centralizado (variação C escolhida pelo Erick)
    drawSymbol("snowflake", pointSize: rect.width * 0.58, color: .white, dx: 0, dy: 0)

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
    try! data.write(to: tmpDir.appendingPathComponent(name))
}

for size in [16, 32, 128, 256, 512] {
    let img = drawIcon(size: CGFloat(size))
    savePNG(img, pixels: size, name: "icon_\(size)x\(size).png")
    savePNG(drawIcon(size: CGFloat(size * 2)), pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", tmpDir.path, "-o", output]
try! task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(at: tmpDir)
print(task.terminationStatus == 0 ? "OK: \(output)" : "iconutil falhou")
exit(task.terminationStatus)
