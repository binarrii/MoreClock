import AppKit
// usage: swift tile.swift out.png Default.png Dark.png TintedDark.png ClearLight.png s64.png s32.png s16.png
let a = CommandLine.arguments
let W = 266*5 + 148 + 160, H = 300
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
NSColor(white: 0.93, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
var x = 10
for i in 2..<6 {
  let bg: NSColor = (i == 3 || i == 4) ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.93, alpha: 1)
  bg.setFill(); NSRect(x: x-5, y: 0, width: 266, height: H).fill()
  NSImage(contentsOfFile: a[i])!.draw(in: NSRect(x: x, y: 22, width: 256, height: 256))
  x += 266
}
ctx.imageInterpolation = .none
NSImage(contentsOfFile: a[6])!.draw(in: NSRect(x: x, y: 22, width: 256, height: 256))   // 64 @4x
x += 266
NSImage(contentsOfFile: a[7])!.draw(in: NSRect(x: x, y: 150, width: 128, height: 128))  // 32 @4x
NSImage(contentsOfFile: a[8])!.draw(in: NSRect(x: x, y: 10, width: 128, height: 128))   // 16 @8x
x += 148
// true size on light, white and dark backdrops
for (j, w) in [CGFloat(0.98), 0.75, 0.12].enumerated() {
  let yy = 200 - j * 90
  NSColor(white: w, alpha: 1).setFill(); NSRect(x: x, y: yy - 10, width: 150, height: 70).fill()
  NSImage(contentsOfFile: a[7])!.draw(in: NSRect(x: x + 20, y: yy + 5, width: 32, height: 32))
  NSImage(contentsOfFile: a[8])!.draw(in: NSRect(x: x + 80, y: yy + 13, width: 16, height: 16))
}
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[1]))
