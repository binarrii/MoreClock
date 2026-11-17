import AppKit

// A plain AppKit entry point. A SwiftUI `App` adds a `Settings` scene that an
// LSUIElement app cannot open reliably from AppKit, and a `MenuBarExtra` cannot
// create a variable number of menu bar items. SwiftUI is still used for every view.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
