# Second Clock (com.sindresorhus.Second-Clock v1.2.0 b6): analysis and blueprint for "MoreClock"

Sources: six independent investigations (App Intents metadata, binary strings, Swift reflection metadata, the asset catalog, one runtime launch, web/App Store), plus one read-only `codesign -d --entitlements` check run during synthesis. Scratch material is under `/tmp/secondclock-analysis/` (subfolders `intents/`, `strings/`, `swift-types/`, `assets/`, `runtime/`, `web/`). Anything marked **(inferred)** has no direct evidence behind it.

---

## 1. What Second Clock is

Second Clock is a free, sandboxed macOS 26+ app that lives only in the menu bar (`LSUIElement=true`). It adds **one** extra clock showing a time zone the user picks. The clock sits next to the system clock and can have a short user prefix in front, such as `🇳🇴 07:58` or `SF 05:15`. The problem it solves: macOS can only show one clock in the menu bar, and the existing world-clock apps carry many features. Second Clock is deliberately minimal ("simple by design"). It follows the system 12/24-hour setting, never shows seconds or dates, has no colors or fonts, and has no analytics. It has no network entitlement of its own. City search still goes to Apple's MapKit service, and system daemons probably broker that call (inferred, not tested). Inside the app it upsells the developer's paid Dato app. The website FAQ also recommends Zone Bar for multiple clocks, and Zone Bar appears in the "More Apps" list.

---

## 2. Feature inventory

| Feature | Details | Evidence source | Confidence |
|---|---|---|---|
| Single extra menu-bar clock | Shows hours and minutes in one chosen zone. No seconds and no date. | web (tagline, screenshot `05:15`), swift-types (only `Symbol.Hour`/`Symbol.Minute` imported, no `Symbol.Second`) | confirmed |
| Built with SwiftUI `MenuBarExtra` (`.menu` style) | Scene is `_TupleScene<(MenuBarExtra<MenuBarItemView+env(\.timeZone), TupleView<menu buttons>>.menuBarExtraStyle(.menu), Settings<SettingsScreen>)>`. This resolves the web/assets guess of a hand-made `NSStatusItem`. | swift-types typeref, strings imports | confirmed |
| Prefix text | Free string shown before the time: flag emoji, any Unicode, or an SF Symbol private-use glyph pasted from the SF Symbols app. Placeholder `Example: SF`. | strings, web FAQ, intents | confirmed |
| Time zone setting | `TimeZone?`; `nil` means the system zone. The settings row shows `Europe/Oslo (UTC+1)`, i.e. the identifier plus the current offset. | swift-types fields, web screenshot | confirmed |
| Follows the system 12/24-hour setting | `DateFormatter.dateFormat(fromTemplate:"j")` is checked for `a`. 12h uses `.hour(.defaultDigits(amPM:.abbreviated))`, otherwise `.hour(.twoDigits(amPM:.abbreviated))`, then `.minute(.twoDigits)` with `FormatStyle.timeZone` set. There is no in-app toggle. | strings (disassembly @0x10011e3e8) | confirmed |
| "24-hour time" explainer row | `TwentyFourHourTimeSetting` reads `\.locale`. Text: "<App> adheres to the “24-hour time” setting in System Settings." Button "Open System Settings" goes to `x-apple.systempreferences:com.apple.Date-Time-Settings.extension`. | strings, swift-types | confirmed |
| Monospaced digits | `Text.monospacedDigit()` is imported. Using it on the label is inferred. | swift-types | likely |
| Minute-granularity refresh | The label uses two `@StateObject` listeners (`ListenOnlyPublisherObservable`, `…2`). `Timer.publish` is imported, and a typeref to `TimelineView<EveryMinuteTimelineSchedule, Never>.Context` shows the minute schedule is used in code. Runtime showed 0 idle wakeups over an ~8 s window, which rules out 1 Hz updates but does not prove minute cadence. The Zone Bar FAQ says "updates once per minute". | swift-types, runtime, web | likely (the exact tick source is unconfirmed) |
| Re-render on system changes | `Merge5` of NotificationCenter publishers (one of them `Delay`ed) plus `Just(())`. Imported names: `NSSystemClockDidChange`, `NSSystemTimeZoneDidChange`, `NSCurrentLocaleDidChange`, `NSCalendarDayChanged`, `NSWorkspaceDidWake`. Which five feed the merge is inferred. | swift-types | likely |
| City/country search picker | `LocationSearchService` (`@Observable`, `MKLocalSearchCompleter` delegate, query debounced through a `PassthroughSubject`). On pick it runs `MKLocalSearch(request: .init(completion:))` and reads the map item's `timeZone`. The `mapItems`/`timeZone` selectors are present, but the exact read is inferred. | strings, swift-types | confirmed (flow), likely (property) |
| Manual picker and fixed offsets | "…" menu with `Etc/GMT±N` fixed zones at the bottom, built from `TimeZone.knownTimeZoneIdentifiers` and filtered on `Etc/`. Quick picks "UTC" and "System". A one-time tip explains it (`TimeZonePicker__manualPickerTip`). | strings, swift-types | confirmed |
| Picker error and empty states | "Failed to get time zone from selection. Try a different location." and "No Results … Apple is having problems returning results for users in China …" | strings | confirmed |
| Launch at login | `LaunchAtLoginToggle` / `LaunchAtLoginObservable` on `SMAppService.mainApp`. Failure alert: "Failed to toggle “launch at login”. This is a problem with macOS, not the app…" | strings, swift-types, web screenshot | confirmed |
| Shortcuts actions (4) | Get/Set Prefix Text and Get/Set Time Zone. All run in the background. Set Time Zone has a dynamic options list. | intents (`extract.actionsdata`), web | confirmed |
| Free-text time zone parsing (intent) | Accepts an IANA id, `UTC+5`/`GMT-3` (mapped to `Etc/GMT`, sign inverted), or `System` (case-insensitive). Half-hour offsets are rejected. | intents, strings | confirmed (inputs/errors), likely (mapping) |
| Menu items | Settings… (⌘,), Divider, About, Send Feedback, FAQ, Website, Rate App, Share App, More Apps by Me, Debug, Quit | swift-types typeref (exact order) | confirmed |
| Menu-bar-item visibility watchdog | Finds its own `NSStatusItem` through `NSStatusBarWindow` and KVOs `isVisible`. Alerts " Menu Bar Item Did Not Appear" and detects Bartender, Ice, Dozer, Barbee and minimalbar. "Do not show this again" is stored in `SS_NSStatusItem_ensureVisibility_shouldNotShowAgain`. | strings, swift-types | likely (shared SSKit code; active use unobserved) |
| First-launch welcome popover | `showWelcomePopover()` with text "Hello, I'm <App>" and a `CAKeyframeAnimation` attention wiggle. The runtime run could not see it because there was no Screen Recording permission. | strings | likely |
| Rate prompt with feedback steering | "Thanks for wanting to rate …" steers bug reports to "Send Feedback to Developer", then `macappstore://…id6450279539?action=write-review` / `RequestReviewAction`. | strings, swift-types | confirmed |
| Dato upsell section | Dismissible section in Settings: "Want more features and settings?" / "• Multiple clocks • Color and font setting • Time travel • And a lot more" / "Check out my Dato app" (id `Settings__datoUpsell`). | strings, swift-types | confirmed |
| Debug / support window | Pages Dashboard, User Defaults, Logs, Files and Settings. Actions: Copy Debug Info, Email Developer, Delete App Data, and AppKit debug toggles. A per-second `TimelineView(EverySecondimelineSchedule)` (sic) is used **here**, not in the clock. | strings, swift-types | confirmed |
| Cmd-drag to reposition | Standard status-item behavior, mentioned in the App Store tip. | web | confirmed |
| No writes on first launch | The prefs domain did not exist before, during or after the run, so defaults live in code. | runtime | confirmed |
| Low idle cost | 0.0% CPU, 0 idle wakeups, ~22 MB, 3 threads (short ~8 s sample only) | runtime | likely |
| App Intents registration and Spotlight donation at launch | Registers with linkd. Clears 1 CoreSpotlight domain and donates ~3.6 KB. The app has no `AppEntity`/`IndexedEntity`, so this is most likely the system's automatic indexing of App Intents actions **(inferred)**. | runtime vs intents | likely (cause inferred) |
| **Not present: iCloud sync** | `Defaults.iCloud` is compiled in, but the entitlements contain only `app-sandbox` (no `ubiquity-kvstore-identifier`), so `NSUbiquitousKeyValueStore` sync cannot work. | codesign check (this synthesis) | confirmed absent |
| **Not present: global hotkey** | A vendored KeyboardShortcuts plus Carbon `RegisterEventHotKey` are compiled in, but there is no app `KeyboardShortcuts.Name` and no Recorder in the Settings tree. The runtime area's "configurable shortcut" claim came from the library string only. | strings, swift-types | likely absent |
| **Not present: IAP or paywall** | StoreKit is used only for `RequestReviewAction`. There are no `Product`/`Transaction` types and no product ids. | strings, swift-types, web | confirmed |
| **Not present: Siri phrases, entities, focus filter, widgets** | `autoShortcuts=[]`, `entities={}`, `queries={}`. No AppShortcutsProvider, SetFocusFilterIntent or WidgetKit. | intents | confirmed |
| Deliberate non-features | Seconds, date, analog clock, color/weight, multiple clocks, localization (English only) | web FAQ | confirmed |
| Legacy multi-instance workaround | "Second Clock 2…6" builds ship with different bundle IDs so several copies can run side by side. | web | confirmed |

Reconciled conflicts:
- **Timeline usage.** The strings area attributed `EverySecondimelineSchedule` to the label. The swift-types typeref binds it to the debug `List`, so the label refresh is minute-based. The runtime idle numbers and the Zone Bar FAQ support this.
- **Status item kind.** It is a `MenuBarExtra`, which creates an `NSStatusItem` internally. The `NSStatusBarButtonLayerHostingView` class and `imageWithSize:flipped:drawingHandler:` are SSKit/hosting internals, not a custom drawn clock.
- **Picker presentation.** Likely a `.popover(isPresented:)` driven by `TimeZoneSetting._isPresented`. SwiftUI `popover(isPresented:attachmentAnchor:arrowEdge:content:)` is imported, and no `sheet` symbol is imported at all.

---

## 3. Settings model

App settings (vendored `Defaults` on `UserDefaults.standard`; nothing is written until changed):

| Setting | Type | Default | UserDefaults key | Evidence |
|---|---|---|---|---|
| Prefix text | `String` | `""` | `prefix` | Code immediate @0x100007074; `Default<String>` in `MenuBarItemView`/`PrefixSetting`; intent text "Leave empty to clear" (likely) |
| Time zone | `TimeZone?` (Codable via the Defaults bridge) | `nil` = system (`TimeZone.autoupdatingCurrent`) | `timeZone` | Code immediate @0x100007004; `Default<TimeZone?>` in `AppMain`/`TimeZoneSetting` (confirmed key; encoding format inferred) |
| Launch at login | `Bool` (live `SMAppService.mainApp.status`) | off | none (system-managed) | `LaunchAtLoginObservable` |

Not settings: 24-hour time (read from the system/locale only) and the global shortcut (no evidence of one).

Internal shared-library keys (SSKit, Defaults, KeyboardShortcuts), all confirmed strings: `SS_firstLaunchDate`, `SS_launchCount`, `SS_previousLaunchedVersion`, `SSApp_requestReview`, `SSApp_wasRelaunched`, `SS_isShowingSettingsAfterRelaunch`, `SS_NSStatusItem_ensureVisibility_shouldNotShowAgain`, `SS_Tooltip_<id>`, `SS_ShowForAppRuns_<id>`, `SS_App_runOnce__<id>`, `KeyboardShortcuts_<name>`, `__DEFAULTS__synchronizeTimestamp`, `__Key_keyboardShortcutsRecorderShowsIndicator`. One-time tip and section ids: `Settings__tip__flagEmoji`, `Settings__datoUpsell`, `TimeZonePicker__manualPickerTip`, `rateOnTheAppStorePrompt`. Which id goes with which prefix family is inferred.

Speculative / probably unused (present in the binary, no evidence the app uses them): `AppAppearance {system, light, dark}`, `showEvenWhenMenuBarItemIsHidden`, Defaults iCloud sync, DockProgress, AudioDevice/TransportType, PowerSourceWatcher, LocationManager.

---

## 4. UX walkthrough

**Menu bar item.** Text only, with no icon: `<prefix> <time>`, e.g. `🇳🇴 07:58` or `05:15`. The separator between prefix and time is inferred to be a space. The time follows the locale and the system 24h setting, with two-digit hours in 24h mode and no AM/PM padding change in 12h mode. Cmd-drag moves it. If macOS hides it (notch or crowded bar), the watchdog alert explains why. On first launch a welcome popover ("Hello, I'm Second Clock") is likely anchored to the item.

**Click: native NSMenu** (`.menu` style), in this exact order:
`Settings…` ⌘, → divider → `About` → `Send Feedback` → `FAQ` → `Website` → `Rate App` → `Share App` → `More Apps by Me` → `Debug` → `Quit`. Whether Debug is always visible or gated (e.g. by the Option key) is not determined.

**Settings window** (SwiftUI `Settings` scene, title "Second Clock Settings", small fixed-size `Form` with `.formStyle(.grouped)`), one `Section`:
1. `Launch at login` toggle
2. 24-hour note (`TwentyFourHourTimeSetting`), which opens an alert or System Settings link. It may not appear in the older official screenshot.
3. `Time zone`: a `LabeledContent` with a dropdown-styled button showing e.g. `Europe/Oslo (UTC+1)`. It opens the **TimeZonePicker**:
   - a search field "Search by city or country" (MapKit autocomplete)
   - a list of `TimeZoneRow` with hover/keyboard highlight
   - empty and error overlays
   - a bottom bar of `Button` + icon-only "…" `Menu` + `Button`. The labels "UTC", "System" and "Pick" exist, with help text "Pick UTC or the system time zone." The exact label placement is inferred. The "…" menu holds the manual-pick tip (first N runs) and `Etc/GMT±N` fixed zones.
4. `Prefix text` TextField, prompt `Example: SF`, footnote "Tip: You could use a [flag emoji](https://emojipedia.org/flags)".
5. Dato upsell section (dismissible).

**Shortcuts (App Intents)**. All are `openAppWhenRun=false`, background, discoverable, no authentication:
- **Get Prefix Text**: returns String ("Prefix Text").
- **Set Prefix Text**: summary "Set prefix text to ${prefix}". Optional String, no autocorrect, smart quotes, smart dashes or capitalization.
- **Get Time Zone**: returns the identifier, or nothing when following the system zone.
- **Set Time Zone**: summary "Set time zone to ${timeZone}". Optional String with `TimeZoneOptionsProvider` (`DynamicOptionsProvider`). Accepts an IANA id, `UTC+5`/`GMT-3`, or `System`. Errors: "Half-hour UTC offsets are not supported. Use the time zone identifier instead." and "Invalid time zone. Use an identifier (for example, "America/Los_Angeles") or UTC offset (for example, "UTC+5")."

The website promotes using these from a Focus-triggered Shortcuts automation. There is no FocusFilterIntent.

---

## 5. Technical architecture as built

- **Binary:** universal Swift, stripped, one module `Second_Clock` with ~25 app types and a large vendored shared layer (SSKit). macOS 26.0 minimum, built with Xcode 26.3 (17C529).
- **Entry:** `@main struct AppMain: App { sskit: SSKit; @Default(.timeZone) }` with body `MenuBarExtra { menu buttons } label: { MenuBarItemView().environment(\.timeZone, timeZone ?? .autoupdatingCurrent /*inferred*/) }.menuBarExtraStyle(.menu)` plus `Settings { SettingsScreen() }`.
- **Label view:** `MenuBarItemView { @Environment(\.timeZone); @StateObject listener (ListenOnlyPublisherObservable2: _start, cancellable, @Published updater); @StateObject listener2 (ListenOnlyPublisherObservable: objectWillChange, cancellable); @Default(.prefix) }`. The listeners exist because `MenuBarExtra` labels do not re-render reliably inside a `TimelineView` (inferred rationale). One fires on minute ticks; the other on the merged system notifications.
- **Formatting:** `Date.FormatStyle` (`.dateTime.hour(...).minute(.twoDigits)`, with `.locale` and `.timeZone`) plus the `"j"` template check. There are no custom pattern strings.
- **Persistence:** vendored sindresorhus/Defaults (`Defaults.Key`, `@Default`, `Defaults.Observable`, Codable bridge for `TimeZone`). Defaults live in code, so nothing is written on first launch.
- **Intents ↔ app:** the intents probably write the same Defaults keys, and the label updates through its Defaults observation (inferred). The intents have no `@Dependency` fields.
- **Time zone search:** MapKit `MKLocalSearchCompleter` → `MKLocalSearch` → `MKMapItem.timeZone` (inferred property). No CLGeocoder. The offline fallback uses `knownTimeZoneIdentifiers` / `Etc/GMT±N` / `TimeZone(secondsFromGMT:)`.
- **Launch at login:** `SMAppService.mainApp.register()/unregister()` wrapped in an ObservableObject.
- **Entitlements (confirmed this pass):** only `com.apple.security.app-sandbox`, plus team and app identifiers. No `network.client`, no iCloud and no location. City search still contacts Apple's MapKit service. That presumably goes through system daemons, but this is inferred: no investigator ran a search inside the sandboxed app. The App Store "No network access" badge only reflects the missing `network.client` entitlement.
- **Assets:** `Assets.car` holds only an Icon Composer (Liquid Glass) AppIcon with light, dark and tinted variants: a gradient background layer and a "9:41" glyph layer. There is no AccentColor and no menu-bar template image. `AppIcon.icns` goes up to 256 px.
- **Monetization:** free, with no ads or IAP. It cross-promotes Dato in Settings, plus More Apps and Rate prompts.
- **Leftover shared code (inferred):** this is why CoreLocation, NaturalLanguage, QuickLookUI, AVFoundation, CoreAudio, CryptoKit, IOKit and Carbon are linked. It includes KeyboardShortcuts, DockProgress, AudioDevice/TransportType (which shows up as an unused AppEnum in the intents metadata), an Introspect-style helper, and the debug window.

---

## 6. Blueprint for "MoreClock"

### 6.1 Stack and the MenuBarExtra vs NSStatusItem choice

| | SwiftUI `MenuBarExtra` | AppKit `NSStatusItem` (+ SwiftUI elsewhere) |
|---|---|---|
| Number of items | One per scene declaration. `SceneBuilder` cannot `ForEach` over dynamic data. You can declare a fixed N with `isInserted:` bindings, which is clunky. | Any number at runtime: create and remove `NSStatusBar.system.statusItem(withLength:)` |
| Label refresh | Second Clock uses ObservableObject listeners. That TimelineView in labels is unreliable is community lore and is **inferred** here. | Set `button.title` directly. Cheapest possible update. |
| Width jitter | Limited control | Monospaced-digit font sized to `NSFont.menuBarFont(ofSize: 0).pointSize`; optional fixed `length` |
| Position persistence | Automatic | `autosaveName` per item; use a stable UUID per clock |
| Menu/popover | `.menu` or `.window` style for free | `item.menu = NSMenu` or a custom NSPopover/NSPanel hosting SwiftUI |
| Secondary-display dimming | Fine | Prefer a plain `title` with `font` over a rich `attributedTitle`. The developer's FAQ says rich text may dim incorrectly (inferred). |

**Recommendation for a multi-clock app:** use an `NSStatusItem` per clock, managed by a `@MainActor` controller. Use SwiftUI for the Settings window (`Settings` scene or a hosted window) and for any popover. Keep `MenuBarExtra` only if you ship a single clock in the MVP.

Packages (all MIT, by the same author, and the ones Second Clock vendors):
- `github.com/sindresorhus/Defaults`: typed keys, Codable, `@Default`, `Defaults.updates()` async streams.
- `github.com/sindresorhus/LaunchAtLogin-Modern`: `LaunchAtLogin.Toggle()`, built on SMAppService.
- `github.com/sindresorhus/KeyboardShortcuts`: only if you add a global hotkey, e.g. one that toggles a "time-travel" panel.
- `github.com/sindresorhus/Settings` (optional): multi-pane settings windows. A plain `Form` in a `Settings` scene is enough for the MVP.

### 6.2 Project structure

```
MoreClock/
  MoreClock.xcodeproj
  MoreClock/
    App/          MoreClockApp.swift, AppDelegate.swift (status-item bootstrap)
    Model/        ClockConfig.swift, Defaults+Keys.swift, TimeZoneParsing.swift
    MenuBar/      StatusItemController.swift, ClockTicker.swift, ClockFormatter.swift
    Settings/     SettingsScreen.swift, ClockListView.swift, ClockEditor.swift
    TimeZonePicker/ TimeZonePicker.swift, LocationSearchService.swift, TimeZoneRow.swift
    Intents/      ClockEntity.swift, ClockQuery.swift, Set/Get*Intent.swift, MoreClockShortcuts.swift
    Resources/    AppIcon.icon (Icon Composer), Localizable.xcstrings
    MoreClock.entitlements
  MoreClockTests/ TimeZoneParsingTests.swift, ClockFormatterTests.swift
```

Info.plist: `LSUIElement = YES`, `LSApplicationCategoryType = public.app-category.utilities`.

### 6.3 Model

```swift
import Defaults
import Foundation

struct ClockConfig: Codable, Hashable, Identifiable, Defaults.Serializable {
    var id = UUID()
    var timeZoneID: String?          // nil = system; store identifier, not encoded TimeZone
    var prefix: String = ""
    var showSeconds = false          // differentiator (Second Clock refuses seconds)
    var isEnabled = true

    var timeZone: TimeZone { timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .autoupdatingCurrent }
}

extension Defaults.Keys {
    static let clocks = Key<[ClockConfig]>("clocks", default: [ClockConfig()])
}
```

### 6.4 Ticker: minute-aligned, or second-aligned only when needed

```swift
import AppKit

@MainActor
final class ClockTicker {
    enum Granularity { case minute, second }
    var granularity: Granularity = .minute { didSet { reschedule() } }
    var onTick: () -> Void = {}
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init() {
        let nc = NotificationCenter.default, wnc = NSWorkspace.shared.notificationCenter
        for name in [Notification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange,
                     NSLocale.currentLocaleDidChangeNotification, .NSCalendarDayChanged] {
            observers.append(nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.fire() }
            })
        }
        observers.append(wnc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire() }
        })
        reschedule()
    }

    private func fire() { onTick(); reschedule() }

    /// Re-arm from wall-clock time every tick so drift, sleep, and clock changes self-correct.
    private func reschedule() {
        timer?.invalidate()
        let now = Date().timeIntervalSinceReferenceDate
        let step: TimeInterval = granularity == .second ? 1 : 60
        let next = (floor(now / step) + 1) * step + 0.005   // just past the boundary
        let t = Timer(fire: Date(timeIntervalSinceReferenceDate: next), interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire() }
        }
        t.tolerance = granularity == .second ? 0.05 : 0.5   // lets macOS coalesce wakeups
        RunLoop.main.add(t, forMode: .common)               // keeps ticking while a menu is open
        timer = t
    }
}
```

Use **one shared ticker** for all clocks. Set its granularity to `.second` only if any enabled clock has `showSeconds`.

### 6.5 Formatter and status items

```swift
enum ClockFormatter {
    static func string(for date: Date, config: ClockConfig, locale: Locale = .autoupdatingCurrent) -> String {
        let uses12h = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)?.contains("a") ?? false
        var style = Date.FormatStyle(locale: locale, timeZone: config.timeZone)
            .hour(uses12h ? .defaultDigits(amPM: .abbreviated) : .twoDigits(amPM: .abbreviated))
            .minute(.twoDigits)
        if config.showSeconds { style = style.second(.twoDigits) }
        let time = date.formatted(style)
        return config.prefix.isEmpty ? time : "\(config.prefix) \(time)"
    }
}

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private var items: [UUID: NSStatusItem] = [:]
    private let clockFont = NSFont.monospacedDigitSystemFont(
        ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)   // match the system clock size
    private let ticker = ClockTicker()
    private var task: Task<Void, Never>?

    override init() {
        super.init()
        ticker.onTick = { [weak self] in self?.refreshTitles() }
        task = Task { [weak self] in
            for await clocks in Defaults.updates(.clocks) { self?.sync(clocks) }
        }
    }

    private func sync(_ clocks: [ClockConfig]) {
        let enabled = clocks.filter(\.isEnabled)
        for (id, item) in items where !enabled.contains(where: { $0.id == id }) {
            NSStatusBar.system.removeStatusItem(item); items[id] = nil
        }
        for clock in enabled where items[clock.id] == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.autosaveName = "clock-\(clock.id.uuidString)"   // stable position across launches
            item.button?.font = clockFont
            let menu = NSMenu()
            menu.identifier = NSUserInterfaceItemIdentifier(clock.id.uuidString)
            menu.delegate = self                                  // filled lazily, so never stale
            item.menu = menu
            items[clock.id] = item
        }
        ticker.granularity = enabled.contains(where: \.showSeconds) ? .second : .minute
        refreshTitles()
    }

    private func refreshTitles() {
        let now = Date()
        for clock in Defaults[.clocks] where clock.isEnabled {
            let title = ClockFormatter.string(for: now, config: clock)
            if items[clock.id]?.button?.title != title { items[clock.id]?.button?.title = title } // skip no-op redraws
        }
    }

    // Rebuilt every time the menu opens, so Settings/intent changes are always reflected.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let id = menu.identifier.flatMap({ UUID(uuidString: $0.rawValue) }),
              let clock = Defaults[.clocks].first(where: { $0.id == id }) else { return }
        let full = Date().formatted(Date.FormatStyle(locale: .autoupdatingCurrent, timeZone: clock.timeZone)
            .weekday(.wide).day().month(.abbreviated).hour().minute())
        let header = NSMenuItem(title: "\(clock.timeZone.displayLabel) — \(full)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(AppDelegate.openSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Quit MoreClock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }
}
```

Opening Settings from an `LSUIElement` app:
- `NSApp.sendAction(Selector(("showSettingsWindow:")), …)` no longer opens the SwiftUI `Settings` scene on macOS 14+.
- Instead, either host a hidden SwiftUI helper that calls `@Environment(\.openSettings)`, or own the settings `NSWindow` yourself.
- Call `NSApp.activate()` first, or the window opens behind other apps.
- Second Clock's SSKit has dedicated helpers for this (`SwiftUIWindowForMenuBarApp`, `SwiftUIPanelForMenuBarApp`, `SS_isShowingSettingsAfterRelaunch`).
- Expect the runtime warning seen in Second Clock: "It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out". It likely comes from SwiftUI hosting inside status items.

### 6.6 Time zone picker (search plus offline list)

```swift
import MapKit
import Observation

@Observable @MainActor
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var query = "" { didSet { debounce() } }
    private(set) var results: [MKLocalSearchCompletion] = []
    private(set) var error: Error?
    @ObservationIgnored private let completer = MKLocalSearchCompleter()
    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    override init() { super.init(); completer.delegate = self; completer.resultTypes = .address }

    private func debounce() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self, query] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            self.completer.queryFragment = query
        }
    }
    nonisolated func completerDidUpdateResults(_ c: MKLocalSearchCompleter) {
        let r = c.results; MainActor.assumeIsolated { self.results = r; self.error = nil }
    }
    nonisolated func completer(_ c: MKLocalSearchCompleter, didFailWithError e: Error) {
        MainActor.assumeIsolated { self.error = e }
    }
    func timeZone(for completion: MKLocalSearchCompletion) async throws -> TimeZone? {
        try await MKLocalSearch(request: .init(completion: completion)).start().mapItems.first?.timeZone
    }
}

enum TimeZoneSelection { case system, zone(TimeZone) }   // failure can never silently mean "system"
struct NoTimeZoneError: LocalizedError {
    var errorDescription: String? { "Couldn't get a time zone for that place. Try a different location." }
}

struct TimeZonePicker: View {
    @State private var service = LocationSearchService()
    @State private var pickError: Error?
    let onPick: (TimeZoneSelection) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search city or country", text: $service.query).textFieldStyle(.roundedBorder).padding()
            List(service.results, id: \.self) { c in
                Button {
                    Task {
                        do {
                            guard let tz = try await service.timeZone(for: c) else { throw NoTimeZoneError() }
                            onPick(.zone(tz))
                        } catch { pickError = error }
                    }
                } label: {
                    VStack(alignment: .leading) { Text(c.title); Text(c.subtitle).foregroundStyle(.secondary) }
                }.buttonStyle(.plain)
            }
            .overlay {
                if let error = service.error {
                    ContentUnavailableView("Search Unavailable", systemImage: "wifi.exclamationmark",
                                           description: Text(error.localizedDescription))
                } else if service.query.isEmpty {
                    ContentUnavailableView("Search for a Place", systemImage: "globe",
                                           description: Text("Type a city or country, or pick from All Time Zones."))
                } else if service.results.isEmpty {
                    ContentUnavailableView.search(text: service.query)
                }
            }
            .alert("Time Zone Not Found", isPresented: Binding(get: { pickError != nil }, set: { if !$0 { pickError = nil } })) {
                Button("OK") { pickError = nil }
            } message: { Text(pickError?.localizedDescription ?? "") }
            HStack {
                Button("System") { onPick(.system) }
                Button("UTC") { onPick(.zone(.gmt)) }
                Spacer()
                Menu("All Time Zones") {                       // offline fallback
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                        if let tz = TimeZone(identifier: id) { Button(tz.displayLabel) { onPick(.zone(tz)) } }
                    }
                }.fixedSize()
            }.padding(8)
        }.frame(width: 360, height: 420)
    }
}

extension TimeZone {
    /// "Europe/Oslo (UTC+1)" — same display convention as Second Clock.
    var displayLabel: String {
        let s = secondsFromGMT(), h = s / 3600, m = abs(s % 3600) / 60
        let off = s == 0 ? "UTC" : "UTC\(h >= 0 ? "+" : "")\(h)" + (m > 0 ? ":\(String(format: "%02d", m))" : "")
        return "\(identifier) (\(off))"
    }
}
```

Offset parsing, shared by the intents and a free-text field. Unlike Second Clock, this supports half-hour offsets:

```swift
enum TimeZoneParseError: Error { case invalid }
func parseTimeZone(_ raw: String) throws -> TimeZoneSelection {
    let s = raw.trimmingCharacters(in: .whitespaces)
    if s.isEmpty || s.caseInsensitiveCompare("system") == .orderedSame { return .system }
    // Offsets FIRST: TimeZone(identifier:) also accepts "GMT+5", so checking it first would give
    // different results depending on the spelling.
    let re = /^(?:UTC|GMT)\s*([+-])(\d{1,2})(?::?(\d{2}))?$/.ignoresCase()
    if let m = s.wholeMatch(of: re) {
        guard let h = Int(m.2), let mins = Int(m.3 ?? "0"), mins < 60 else { throw TimeZoneParseError.invalid }
        let sign = m.1 == "-" ? -1 : 1
        let total = sign * (h * 3600 + mins * 60)
        guard (-12 * 3600)...(14 * 3600) ~= total else { throw TimeZoneParseError.invalid }
        if total == 0 { return .zone(.gmt) }
        if mins == 0, let etc = TimeZone(identifier: "Etc/GMT\(sign > 0 ? "-" : "+")\(h)") { return .zone(etc) } // Etc signs are inverted
        guard let fixed = TimeZone(secondsFromGMT: total) else { throw TimeZoneParseError.invalid }        // fixed, no DST
        return .zone(fixed)
    }
    guard let tz = TimeZone(identifier: s) else { throw TimeZoneParseError.invalid }
    return .zone(tz)
}
```

Unit-test at least: `GMT+5`, `utc+14`, `UTC-3:30`, `UTC+5:75` (reject), `UTC-13` (reject), `UTC+0`, `System`, `America/Los_Angeles`, and garbage.

### 6.7 App Intents, going further than the original

Model each clock as an `AppEntity` (`ClockEntity` with id, name, timeZone, prefix) and back it with an `EntityQuery` (plus an `EntityStringQuery` for name matching). Then add:
- `SetClockTimeZoneIntent(clock:, timeZone: String)` and `SetClockPrefixIntent`, using the `parseTimeZone` above with `CustomLocalizedStringResourceConvertible` errors.
- `AddClockIntent` / `RemoveClockIntent` / `ToggleClockIntent`.
- `GetTimeInZoneIntent`, which returns a formatted time or a `Date`. Useful in Shortcuts.
- An `AppShortcutsProvider` with phrases such as "Show \(.applicationName) clocks". Second Clock has none.
- Optional: a `SetFocusFilterIntent` that swaps the clock set per Focus. Second Clock relies on users building Shortcuts automations for this.

Keep `openAppWhenRun = false` and write through `Defaults`. The `Defaults.updates` stream in the controller picks up the change live.

### 6.8 Sandbox and entitlements

- `com.apple.security.app-sandbox = true`. This is the only entitlement Second Clock has, and its MapKit search works with it. Verify early in your own build. If `MKLocalSearch` fails in the sandbox, add `com.apple.security.network.client`.
- Add `com.apple.developer.ubiquity-kvstore-identifier` only if you ship iCloud sync of clocks (Defaults `iCloud` support).
- No location entitlement is needed for city search. Add `com.apple.security.personal-information.location` plus a usage string only if you offer "use my current location".
- Launch at login through SMAppService needs no entitlement.

### 6.9 MVP vs v2

**MVP (parity plus the headline differentiator):**
- N clocks, each its own status item, with prefix, time zone and autosaved position
- System 12/24h, minute-aligned updates, monospaced digits
- Settings window with an add/remove/reorder clock list, the picker (search plus offline list) and Launch at login
- 4–6 App Intents built on a `ClockEntity`
- Hidden-menu-bar-item hint, **as a heuristic only**:
  - `NSStatusItem.isVisible` tracks user removal (Cmd-drag out), not notch or overflow hiding.
  - On macOS 26 the status-item windows are scenes hosted by `com.apple.MenuBarAgent`, not by the app's process, so window or occlusion checks may be unreliable.
  - Second Clock's own alert admits false positives and has a variant for auto-hidden menu bars.
  - Always point users to **System Settings › Menu Bar › Allow in the Menu Bar**.

**v2 ideas to set it apart (Second Clock leaves all of these out on purpose):**
- Per-clock seconds, using the 1 Hz aligned ticker only when enabled
- Optional date or weekday token, or a custom format template via `DateFormatter.dateFormat(fromTemplate:)` so it stays localized
- A "Combined" mode: several zones in one status item (`🇺🇸 09:15 · 🇯🇵 23:15`), saving menu bar space on notched Macs
- Relative-offset display (`+8h`) and a day-change marker (`+1d`)
- A time-travel slider in a popover; a global hotkey (KeyboardShortcuts) to open it
- A meeting planner grid across the configured zones
- A WidgetKit desktop widget and a Control Center `ControlWidget`
- Focus filters, AppShortcutsProvider phrases, Spotlight `IndexedEntity` for clocks
- iCloud sync of clocks
- Localization (Second Clock is English only)
- An "Offline" badge on fixed-offset zones, plus a warning that fixed offsets do not follow DST

Use your own name, icon and copy. Do not reuse the "9:41" glass-digits icon concept or the gradient art.

---

## 7. Open questions / not determined

1. **Label rendering details:** the exact separator between prefix and time, whether `monospacedDigit()` is applied, and the exact tick source (`Timer.publish`, `Task.sleep(until:)` or `EveryMinuteTimelineSchedule` entries). The five notifications in the `Merge5` are inferred. A screenshot was blocked because Screen Recording was not granted.
2. **Whether Debug is always shown in the menu,** and whether the welcome popover actually appears on first launch.
3. **Picker button layout:** the exact roles and placement of the "UTC", "System" and "Pick" buttons. Presentation is likely a popover; see §2.
12. **Date formatting:** `Date.formatted(date:time:)` with `.abbreviated`/`.shortened`/`.omitted` is imported. Is a date line shown anywhere, perhaps in the debug window?
13. **Screen lock/unlock:** are the `com.apple.screenIsLocked`/`screenIsUnlocked` distributed-notification observers used as extra refresh triggers?
4. **`TimeZoneOptionsProvider.results()` content:** all `knownTimeZoneIdentifiers`? Does it include "System" and the UTC±N offsets?
5. **Get Time Zone in system mode:** does it return `nil` or `""`?
6. **Stored encoding of `timeZone`:** Defaults Codable JSON of `TimeZone` or a plain identifier string. Confirming needs a written prefs plist, which macOS App Data protection blocked from reading.
7. **The MKMapItem property used** (`timeZone`, inferred) and `MKLocalSearchCompleter.resultTypes` or region settings.
8. **What the ~3.6 KB CoreSpotlight donation at launch contains.** It is most likely system App Intents action indexing (the app declares no entities); the log content is `<private>`.
9. **How MapKit search works with only the `app-sandbox` entitlement** (system-daemon brokering, inferred). Check this in your own build.
10. **Dark and tinted icon appearance** is inferred from layer data, not seen. The "9:41" font is unconfirmed (it looks like SF Pro Rounded Bold).
11. **Whether SSKit's distributed-notification hooks** (`:showSettings`, `:showDebugWindow`, …) are active.
---

## 8. Extra notes from the review pass

- **Two visibility-watchdog alert variants.** One covers crowded or notched bars and Bartender/Ice. It includes the line "This check can have false-positives". The other says "Disregard this message if you have the menu bar set to auto hide. It will not be shown again." Auto-hide menu bars are therefore a known false-positive case to handle.
- **macOS 26 status items are hosted out-of-process.** Their windows are scenes owned by `com.apple.MenuBarAgent`, not your pid. This matters for any window inspection, watchdog or screenshot approach.
- **Picker implementation patterns** recovered from typerefs:
  - a custom `SearchField` (an `NSSearchField` wrapper with `controlSize`)
  - `ScrollViewReader` plus `onChange` for arrow-key selection
  - a hidden `Button` bound to Return to pick
  - `AccessoryBarButtonStyle` for the bottom bar
  - hover regions on rows
  - `enum SearchResult { case location(MKLocalSearchCompletion), fixedOffset(TimeZone) }`
  - `onPick: (Result<TimeZone?, Error>) -> ()` with a `State<Error?>` alert, which the sketch in §6.6 now mirrors through `TimeZoneSelection`.
- **Optional seconds mode in SwiftUI.** The Debug view wraps `PeriodicTimelineSchedule` in a custom "every second" schedule. This is a ready pattern if you render a clock inside a SwiftUI view (for example, a popover).
- **Past-bug hint.** The FAQ says legacy copies "stopped observing its selected time zone". Test that settings changes made through intents, after sleep/wake, and after a time zone change are picked up live.
- **Version and OS history.** 1.0.0 (Jan 2024) required macOS 14, 1.1.0 required macOS 15, and 1.2.0 (Mar 2026) requires macOS 26. The App Store privacy label is "Data Not Collected".
- **Useful open-source references:** Clocker (github.com/n0shake/clocker), and MenuClock (MIT, SwiftUI `MenuBarExtra` with a minute-aligned ticker, github.com/satsdisco/MenuClock). The developer's own Zone Bar shows the multi-clock end state: up to 10 clocks, names, a time-travel slider and a global shortcut.
- **Raw evidence:** `/tmp/secondclock-analysis/` holds the extracted strings, demangled types, App Intents dump, asset info, icon PNGs, runtime logs and `findings.json`. It lives in `/tmp`, so copy anything you want to keep.
