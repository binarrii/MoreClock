import AppKit
import SwiftUI

/// The app owns its Settings window, so it opens reliably from a menu bar item.
/// Native toolbar tabs: General, Clocks, then About. Each tab sizes the window to its own
/// content, and the window title follows the selected tab, as in System Settings.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    init() {
        let tabs = SettingsTabViewController()
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(Self.tab(String(localized: "General"), symbol: "gearshape", root: GeneralSettingsView()))
        tabs.addTabViewItem(Self.tab(String(localized: "Clocks"), symbol: "clock", root: ClocksSettingsView()))
        tabs.addTabViewItem(Self.tab(String(localized: "About"), symbol: "info.circle", root: AboutSettingsView()))
        tabs.view.userInterfaceLayoutDirection = AppLayout.appKit

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.contentView?.userInterfaceLayoutDirection = AppLayout.appKit
        tabs.restoreSelection()
        window.title = tabs.title ?? String(localized: "General")
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func tab(_ label: String, symbol: String, root: some View) -> NSTabViewItem {
        let hosting = NSHostingController(rootView: root.environment(\.layoutDirection, AppLayout.swiftUI))
        hosting.sizingOptions = [.preferredContentSize] // the tab controller resizes the window per tab
        hosting.title = label
        let item = NSTabViewItem(viewController: hosting)
        item.label = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        return item
    }

    func show() {
        guard let window else { return }
        let wasVisible = window.isVisible
        if !wasVisible { window.center() }
        // An LSUIElement app is not active by default. Without activating, the window opens
        // behind the frontmost app.
        NSApp.activate()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        // macOS 14+ may refuse activation (for example when a background process launched the app).
        // Bring the window forward anyway; it becomes key as soon as the user clicks it.
        window.orderFrontRegardless()
        // Open with nothing focused. Otherwise SwiftUI focuses the first text field (a clock's
        // Name) with its text selected, and one stray keystroke would replace it.
        if !wasVisible {
            DispatchQueue.main.async { window.makeFirstResponder(nil) }
        }
    }
}

/// Remembers the last selected tab between openings and launches.
private final class SettingsTabViewController: NSTabViewController {
    private static let key = "settingsSelectedTab"
    // Adding tabs or loading the view selects the first tab. Capture the previous selection
    // before those callbacks, and don't let them overwrite it while the window is being built.
    private let initialSelectionIndex = UserDefaults.standard.integer(forKey: SettingsTabViewController.key)
    private var hasRestoredSelection = false

    func restoreSelection() {
        if tabViewItems.indices.contains(initialSelectionIndex) {
            selectedTabViewItemIndex = initialSelectionIndex
        }
        hasRestoredSelection = true
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        if let label = tabViewItem?.label { view.window?.title = label }
        guard hasRestoredSelection else { return }
        UserDefaults.standard.set(selectedTabViewItemIndex, forKey: Self.key)
        // Switching tabs should not select the first clock's Name text for replacement.
        DispatchQueue.main.async { [weak self] in self?.view.window?.makeFirstResponder(nil) }
    }
}
