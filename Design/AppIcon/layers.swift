import AppKit
// MoreClock final icon layers (refined "constellation"). usage: swift layers.swift <AssetsDir>  (or ./render.sh [tileName])
// Coordinates below are top-left origin (converted to AppKit bottom-left internally).
let outDir = CommandLine.arguments[1]
let S: CGFloat = 1024

func P(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: S - y) }
func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> NSBezierPath {
  NSBezierPath(ovalIn: NSRect(x: cx - r, y: S - cy - r, width: 2*r, height: 2*r))
}
// Rounded hand from center pointing at clock angle (degrees, 0 = 12 o'clock), as a capsule path.
func hand(_ cx: CGFloat, _ cy: CGFloat, angle: CGFloat, length: CGFloat, width: CGFloat, tail: CGFloat = 0) -> NSBezierPath {
  let p = NSBezierPath(roundedRect: NSRect(x: -width/2, y: -tail - width/2, width: width, height: length + tail + width/2),
                       xRadius: width/2, yRadius: width/2)
  var t = AffineTransform()
  t.translate(x: cx, y: S - cy)
  t.rotate(byDegrees: -angle)
  p.transform(using: t)
  return p
}
func handsFor(h: CGFloat, m: CGFloat) -> (CGFloat, CGFloat) { ((h.truncatingRemainder(dividingBy: 12) + m/60) * 30, m * 6) }

func layer(_ name: String, _ draw: (CGContext) -> Void) {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8, samplesPerPixel: 4,
                             hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  let ctx = NSGraphicsContext(bitmapImageRep: rep)!
  NSGraphicsContext.current = ctx
  ctx.shouldAntialias = true
  draw(ctx.cgContext)
  NSGraphicsContext.restoreGraphicsState()
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}

// ---- Geometry ----
import Foundation
let env = ProcessInfo.processInfo.environment
func ev(_ k: String, _ d: CGFloat) -> CGFloat { env[k].flatMap { Double($0) }.map { CGFloat($0) } ?? d }
struct Face { let cx, cy, r, hour, minute: CGFloat }
let dx: CGFloat = ev("DX", 0), dy: CGFloat = ev("DY", -12)        // whole-cluster optical shift
let front = Face(cx: 618 + dx, cy: 594 + dy, r: 280, hour: ev("FH", 12), minute: ev("FM", 22))   // large, lower-right, in front
let back  = Face(cx: 370 + dx, cy: 352 + dy, r: 206, hour: 9, minute: 5)                       // teal, behind, upper-left
let small = Face(cx: 288 + dx, cy: 764 + dy, r: ev("SR", 134), hour: ev("SH", 4), minute: ev("SM", 0))              // amber 'day' face, lower-left

func handsPath(_ f: Face, hourW: CGFloat, minW: CGFloat, hub: CGFloat, hourLen: CGFloat, minLen: CGFloat) -> NSBezierPath {
  let (ha, ma) = handsFor(h: f.hour, m: f.minute)
  let path = NSBezierPath()
  path.append(hand(f.cx, f.cy, angle: ha, length: f.r * hourLen, width: hourW))
  path.append(hand(f.cx, f.cy, angle: ma, length: f.r * minLen, width: minW))
  path.append(circle(f.cx, f.cy, hub))
  path.windingRule = .nonZero
  return path
}
func tick(_ f: Face, angle: CGFloat, w: CGFloat, len: CGFloat, inset: CGFloat) -> NSBezierPath {
  let p = NSBezierPath(roundedRect: NSRect(x: -w/2, y: f.r - inset - len, width: w, height: len), xRadius: w/2, yRadius: w/2)
  var t = AffineTransform(); t.translate(x: f.cx, y: S - f.cy); t.rotate(byDegrees: -angle)
  p.transform(using: t); return p
}
func ticks(_ f: Face, w: CGFloat, len: CGFloat, inset: CGFloat) -> NSBezierPath {
  let path = NSBezierPath()
  for a in stride(from: 0, to: 360, by: 90) { path.append(tick(f, angle: CGFloat(a), w: w, len: len, inset: inset)) }
  return path
}
let white = NSColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
let navy = NSColor(displayP3Red: 0.08, green: 0.12, blue: 0.35, alpha: 1)

// Teal back face: colored disc; hands, 12 o'clock tick and hub are a separate non-glass layer.
layer("back-face") { _ in
  NSColor(displayP3Red: 0.10, green: 0.78, blue: 0.80, alpha: 1).setFill()
  circle(back.cx, back.cy, back.r).fill()
}
layer("back-hands") { _ in
  white.setFill()
  handsPath(back, hourW: 40, minW: 32, hub: 24, hourLen: 0.50, minLen: 0.74).fill()
  tick(back, angle: 0, w: 22, len: 56, inset: 22).fill()
}
// Amber 'day' face with dark navy hands and a white centre pin.
layer("small-face") { _ in
  NSColor(displayP3Red: 1.00, green: 0.72, blue: 0.20, alpha: 1).setFill()
  circle(small.cx, small.cy, small.r).fill()
}
layer("small-hands") { _ in
  navy.setFill()
  handsPath(small, hourW: 32, minW: 27, hub: 22, hourLen: 0.46, minLen: 0.68).fill()
  white.setFill()
  circle(small.cx, small.cy, small.r * 0.07).fill()
}
layer("front-face") { _ in
  NSColor(displayP3Red: 0.00, green: 0.33, blue: 0.88, alpha: 1).setFill()
  circle(front.cx, front.cy, front.r).fill()
}
layer("front-hands") { _ in
  white.setFill()
  handsPath(front, hourW: 52, minW: 42, hub: 34, hourLen: 0.48, minLen: 0.80).fill()
  ticks(front, w: 30, len: 46, inset: 30).fill()
}
// Light rim on the front face (non-glass), baked at 35% white.
layer("front-rim") { _ in
  NSColor(displayP3Red: 1, green: 1, blue: 1, alpha: ev("RIMA", 0.35)).setStroke()
  let p = circle(front.cx, front.cy, front.r - 5); p.lineWidth = 9; p.stroke()
}
