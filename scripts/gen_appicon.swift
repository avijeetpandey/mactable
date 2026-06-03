#!/usr/bin/env swift
//
// gen_appicon.swift
// Generates a squircle MacTable app icon at all required macOS sizes.
//

import AppKit
import CoreGraphics

let outputDir = "mactable/Assets.xcassets/AppIcon.appiconset"
let sizes: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func makeIcon(size px: Int) -> Data? {
    let dim = CGFloat(px)
    guard let ctx = CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let inset: CGFloat = dim * 0.04
    let rect = CGRect(x: inset, y: inset, width: dim - 2*inset, height: dim - 2*inset)
    let radius = (dim - 2*inset) * 0.225
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    let colors = [
        CGColor(red: 0.13, green: 0.20, blue: 0.42, alpha: 1.0),
        CGColor(red: 0.18, green: 0.50, blue: 0.86, alpha: 1.0),
        CGColor(red: 0.30, green: 0.78, blue: 0.95, alpha: 1.0)
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!

    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: dim), end: CGPoint(x: dim, y: 0), options: [])

    let highlight = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: [
                                CGColor(red: 1, green: 1, blue: 1, alpha: 0.32),
                                CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)
                               ] as CFArray,
                               locations: [0.0, 1.0])!
    ctx.drawLinearGradient(highlight, start: CGPoint(x: 0, y: dim), end: CGPoint(x: 0, y: dim * 0.55), options: [])
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    let bottomShadow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [
                                    CGColor(red: 0, green: 0, blue: 0, alpha: 0.0),
                                    CGColor(red: 0, green: 0, blue: 0, alpha: 0.22)
                                  ] as CFArray, locations: [0.6, 1.0])!
    ctx.drawLinearGradient(bottomShadow, start: CGPoint(x: 0, y: dim*0.4), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()

    // Stylized stacked database cylinders glyph
    ctx.saveGState()
    let center = CGPoint(x: dim/2, y: dim/2)
    let glyphW = dim * 0.46
    let glyphH = dim * 0.54
    let glyphRect = CGRect(x: center.x - glyphW/2, y: center.y - glyphH/2, width: glyphW, height: glyphH)
    let diskHeight = glyphH / 5.5

    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    let wallY1 = glyphRect.minY + diskHeight/2
    let wallH = glyphH - diskHeight
    ctx.fill(CGRect(x: glyphRect.minX, y: wallY1, width: glyphW, height: wallH))

    func drawDisk(at y: CGFloat) {
        let r = CGRect(x: glyphRect.minX, y: y, width: glyphW, height: diskHeight)
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.12))
        ctx.fillEllipse(in: r.offsetBy(dx: 0, dy: -dim*0.005))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
        ctx.fillEllipse(in: r)
    }
    drawDisk(at: glyphRect.minY)
    drawDisk(at: glyphRect.minY + (glyphH - diskHeight) * 0.5)
    drawDisk(at: glyphRect.minY + glyphH - diskHeight)

    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.06))
    ctx.setLineWidth(max(1, dim * 0.005))
    ctx.strokeEllipse(in: CGRect(x: glyphRect.minX, y: glyphRect.minY + glyphH - diskHeight,
                                 width: glyphW, height: diskHeight))
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.setLineWidth(max(1, dim * 0.012))
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.strokePath()
    ctx.restoreGState()

    guard let cgImage = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])
}

let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for entry in sizes {
    guard let data = makeIcon(size: entry.px) else { continue }
    let path = "\(outputDir)/\(entry.name)"
    try? data.write(to: URL(fileURLWithPath: path))
    print("wrote \(entry.name) (\(entry.px)px, \(data.count) bytes)")
}

let contents: [String: Any] = [
    "images": sizes.map { e -> [String: String] in
        let comps = e.name.replacingOccurrences(of: "icon_", with: "").replacingOccurrences(of: ".png", with: "")
        let scale = comps.contains("@2x") ? "2x" : "1x"
        let size = comps.replacingOccurrences(of: "@2x", with: "")
        return ["idiom": "mac", "scale": scale, "size": size, "filename": e.name]
    },
    "info": ["author": "xcode", "version": 1]
]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: URL(fileURLWithPath: "\(outputDir)/Contents.json"))
print("Updated Contents.json")
