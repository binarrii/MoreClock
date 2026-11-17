import AppKit
import MoreClockKit
import Observation

/// Keeps one `NSStatusItem` for each clock in `ClockStore` in step with it.
///
/// Hidden clocks keep their item, with `isVisible = false`. `removeStatusItem` erases the
/// autosaved menu bar position, so removing and re-creating the item would lose where the
/// user ⌘-dragged it. Items are removed only when their clock is deleted.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let store: ClockStore
    private let openSettings: () -> Void
    private var items: [UUID: NSStatusItem] = [:]
    private var visibilityObservations: [UUID: NSKeyValueObservation] = [:]
    /// Set while this code changes `isVisible`, so the KVO handler only reacts to the user.
    private var isApplyingVisibility = false
    private var ticker: ClockTicker?
    private var observationTask: Task<Void, Never>?

    /// Same size as the system clock, with fixed-width digits so the item doesn't jitter.
    private let regularFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
    private let boldFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .bold)

    init(store: ClockStore, openSettings: @escaping () -> Void) {
        self.store = store
        self.openSettings = openSettings
        super.init()

        ticker = ClockTicker { [weak self] in self?.refreshTitles() }
        sync(store.clocks)
        observationTask = Task { [weak self, store] in
            for await clocks in Observations({ store.clocks }) {
                self?.sync(clocks)
            }
        }
    }

    // MARK: Items

    private func sync(_ clocks: [ClockConfig]) {
        let ids = Set(clocks.map(\.id))

        for (id, item) in items where !ids.contains(id) {
            visibilityObservations[id] = nil // stop observing first; removal must not count as a user action
            NSStatusBar.system.removeStatusItem(item) // also clears its saved position, which is right for a deleted clock
            items[id] = nil
        }

        // New items appear to the left of existing ones. Creating them in reverse puts the
        // first clock in the list leftmost on first launch. After that, autosaveName restores
        // wherever the user ⌘-dragged them.
        for clock in clocks.reversed() where items[clock.id] == nil {
            items[clock.id] = makeItem(for: clock)
        }

        isApplyingVisibility = true
        for clock in clocks {
            guard let item = items[clock.id], item.isVisible != clock.isEnabled else { continue }
            item.isVisible = clock.isEnabled
        }
        isApplyingVisibility = false

        ticker?.granularity = clocks.contains { $0.isEnabled && $0.showSeconds } ? .second : .minute
        refreshTitles()
    }

    private func makeItem(for clock: ClockConfig) -> NSStatusItem {
        let id = clock.id
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "MoreClock.\(id.uuidString)" // restores position and the saved visibility
        item.behavior = .removalAllowed
        item.button?.font = clock.isBold ? boldFont : regularFont
        item.button?.alignment = .center

        let menu = NSMenu()
        menu.identifier = NSUserInterfaceItemIdentifier(id.uuidString)
        menu.delegate = self
        menu.userInterfaceLayoutDirection = AppLayout.appKit
        item.menu = menu

        // ⌘-dragging the item out of the menu bar hides the clock. Mirror that in Settings.
        visibilityObservations[id] = item.observe(\.isVisible, options: [.new]) { [weak self] _, change in
            guard change.newValue == false else { return }
            MainActor.assumeIsolated {
                guard let self, !self.isApplyingVisibility else { return }
                self.store.update(id) { $0.isEnabled = false }
            }
        }
        return item
    }

    private func refreshTitles() {
        let now = Date()
        for clock in store.clocks where clock.isEnabled {
            guard let button = items[clock.id]?.button else { continue }
            let font = clock.isBold ? boldFont : regularFont
            if button.font != font { button.font = font }
            let title = ClockFormatter.title(for: now, config: clock)
            let styledTitle = MenuBarTitleStyle.title(title, prefix: clock.prefix, font: font)
            if !button.attributedTitle.isEqual(to: styledTitle) {
                button.attributedTitle = styledTitle // Skip redraws that change nothing.
            }
            let tip = clock.timeZone.displayLabel(at: now)
            if button.toolTip != tip { button.toolTip = tip }
        }
    }

    // MARK: Menu

    /// Rebuilt each time the menu opens, so it always reflects the latest settings.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let raw = menu.identifier?.rawValue,
              let id = UUID(uuidString: raw),
              let clock = store.clock(id: id)
        else { return }

        let now = Date()
        let zone = clock.timeZone
        menu.addItem(.sectionHeader(title: clock.displayName))
        addInfo(ClockFormatter.longString(for: now, timeZone: zone), to: menu)
        addInfo(zone.displayLabel(at: now), to: menu)
        addInfo(Self.relativeDescription(of: zone, at: now), to: menu)

        menu.addItem(.separator())
        addAction(String(localized: "Copy Time"), #selector(copyTime(_:)), id: id, to: menu)
        addAction(String(localized: "Hide This Clock"), #selector(hideClock(_:)), id: id, to: menu)
        menu.addItem(.separator())
        addAction(String(localized: "Settings…"), #selector(openSettingsAction(_:)), key: ",", to: menu)
        let quit = NSMenuItem(title: String(localized: "Quit MoreClock"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    /// "8 hr ahead of local time", "4 hr, 30 min behind local time" or "Same time as local time".
    /// The duration is formatted for the user's locale.
    static func relativeDescription(of zone: TimeZone, at date: Date) -> String {
        let delta = ClockFormatter.offsetDifference(of: zone, from: .autoupdatingCurrent, at: date)
        guard delta != 0 else { return String(localized: "Same time as local time") }
        let amount = Duration.seconds(abs(delta)).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        return delta > 0
            ? String(localized: "\(amount) ahead of local time", comment: "%@ is a duration such as “8 hr” or “4 hr, 30 min”")
            : String(localized: "\(amount) behind local time", comment: "%@ is a duration such as “8 hr” or “4 hr, 30 min”")
    }

    private func addInfo(_ title: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func addAction(_ title: String, _ action: Selector, id: UUID? = nil, key: String = "", to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.representedObject = id
        menu.addItem(item)
    }

    @objc private func copyTime(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID, let clock = store.clock(id: id) else { return }
        let time = ClockFormatter.timeString(for: .now, timeZone: clock.timeZone, showSeconds: clock.showSeconds)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(time, forType: .string)
    }

    @objc private func hideClock(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        store.update(id) { $0.isEnabled = false }
    }

    @objc private func openSettingsAction(_ sender: NSMenuItem) {
        openSettings()
    }
}
