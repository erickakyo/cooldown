#!/usr/bin/env swift
// Gera o AppIcon.icns do Cooldown a partir do arquivo PNG de origem.
// Uso: swift scripts/make_icon.swift <saida.icns>

import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"
let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("CooldownIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: tmpDir)
try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

// Carrega o ícone original da pasta _assets
let currentDir = FileManager.default.currentDirectoryPath
let sourcePath = currentDir + "/_assets/macos - icon - cooldown.png"
guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Erro: não foi possível carregar o ícone de origem em \(sourcePath)")
    exit(1)
}

func resizeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    sourceImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1)
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
    let img = resizeIcon(size: CGFloat(size))
    savePNG(img, pixels: size, name: "icon_\(size)x\(size).png")
    savePNG(resizeIcon(size: CGFloat(size * 2)), pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", tmpDir.path, "-o", output]
try! task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(at: tmpDir)
print(task.terminationStatus == 0 ? "OK: \(output)" : "iconutil falhou")
exit(task.terminationStatus)
