import Observation
import ServiceManagement

/// A thin wrapper around `SMAppService.mainApp`. The system owns the state, so the app
/// stores nothing itself.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var status = SMAppService.mainApp.status
    var errorMessage: String?

    var isEnabled: Bool {
        get { status == .enabled || status == .requiresApproval }
        set { set(newValue) }
    }

    var needsApproval: Bool { status == .requiresApproval }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    private func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = String(localized: "Couldn’t change “Launch at login”: \(error.localizedDescription)")
        }
        refresh()
    }
}
