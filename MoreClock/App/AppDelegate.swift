import AppIntents
import AppKit
import MoreClockKit
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItems: StatusItemController?
    private lazy var settingsWindow = SettingsWindowController()
    private var shortcutParametersTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make()
        let store = ClockStore.shared
        statusItems = StatusItemController(store: store) { [weak self] in self?.showSettings() }
        keepShortcutParametersCurrent(store)

        // Show Settings when nothing else would show that the app is running: on the first
        // launch, or when every clock is hidden. An app without a Dock icon or a menu bar
        // item looks broken. Login-item launches stay quiet.
        let launchedKey = "hasLaunchedBefore"
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: launchedKey)
        UserDefaults.standard.set(true, forKey: launchedKey)
        let nothingVisible = !store.clocks.contains(where: \.isEnabled)
        let wasRelaunchedForSettings = AppRelaunch.consumeSettingsRequest()
        if isFirstLaunch || wasRelaunchedForSettings || (nothingVisible && !Self.launchedAsLoginItem) {
            showSettings()
        }
    }

    /// Opening the app again from Finder or Spotlight shows Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func showSettings() {
        settingsWindow.show()
    }

    @objc func showSettingsAction(_ sender: Any?) {
        showSettings()
    }

    /// Siri phrases that take a clock ("What time is it on <clock>…") need the system to re-read
    /// `suggestedEntities()` whenever clocks are added, removed or renamed.
    private func keepShortcutParametersCurrent(_ store: ClockStore) {
        shortcutParametersTask = Task { [store] in
            var last: [String]?
            for await names in Observations({ store.clocks.map { "\($0.id)|\($0.displayName)" } }) {
                guard names != last else { continue }
                last = names
                MoreClockShortcuts.updateAppShortcutParameters()
            }
        }
    }

    private static var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication
        else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
