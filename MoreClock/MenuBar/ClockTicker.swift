import AppKit

/// Fires just after each wall-clock minute boundary, or each second when `granularity` is
/// `.second`. It also fires right away when the clock, time zone, locale or date changes
/// and on wake.
///
/// Each tick re-arms a one-shot timer from the current time instead of repeating, so drift,
/// sleep and manual clock changes correct themselves. The tolerance lets macOS coalesce
/// wakeups.
@MainActor
final class ClockTicker {
    enum Granularity { case minute, second }

    var granularity: Granularity = .minute {
        didSet { if granularity != oldValue { reschedule() } }
    }

    private let onTick: () -> Void
    private var timer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(onTick: @escaping () -> Void) {
        self.onTick = onTick

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange,
            NSLocale.currentLocaleDidChangeNotification, // includes the 24-hour time switch
            .NSCalendarDayChanged,
        ]
        for name in names {
            observe(center, name)
        }
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification)
        reschedule()
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire() }
        }
        observers.append((center, token))
    }

    private func fire() {
        onTick()
        reschedule()
    }

    private func reschedule() {
        timer?.invalidate()
        let step: TimeInterval = granularity == .second ? 1 : 60
        let now = Date().timeIntervalSinceReferenceDate
        let next = (floor(now / step) + 1) * step + 0.01 // just past the boundary
        let timer = Timer(fire: Date(timeIntervalSinceReferenceDate: next), interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.fire() }
        }
        timer.tolerance = granularity == .second ? 0.05 : 0.5
        RunLoop.main.add(timer, forMode: .common) // keeps ticking while a menu is open
        self.timer = timer
    }
}
