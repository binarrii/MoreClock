import Foundation
import Observation

/// The single source of truth for the clock list. The menu bar, the Settings window and the
/// App Intents all read and write through `ClockStore.shared`. Intents run in the app's
/// process, so every change reaches the UI through Observation without polling UserDefaults.
@MainActor
@Observable
public final class ClockStore {
    public static let shared = ClockStore()

    public static let defaultClocks = [ClockConfig(timeZoneID: "UTC", prefix: "UTC")]

    public var clocks: [ClockConfig] {
        didSet {
            guard clocks != oldValue else { return }
            save()
        }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    /// Nothing is written until the list changes, so defaults can evolve in code.
    public init(defaults: UserDefaults = .standard, key: String = "clocks") {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ClockConfig].self, from: data) {
            clocks = decoded.map { clock in
                // Earlier Maps selections could save a Hong Kong/Macau place with Shanghai's
                // identifier. Repair only that known combination; leave manually chosen zones
                // (which have no placeName) and all other clock settings untouched.
                guard clock.timeZoneID == "Asia/Shanghai", let placeName = clock.placeName,
                      let corrected = PlaceTimeZoneResolver.resolve(
                        reportedZone: clock.timeZone, regionCode: "CN", placeName: placeName
                      ), corrected.identifier != clock.timeZoneID
                else { return clock }
                var repaired = clock
                repaired.timeZoneID = corrected.identifier
                return repaired
            }
            if clocks != decoded { save() }
        } else {
            clocks = Self.defaultClocks
        }
    }

    public func clock(id: UUID) -> ClockConfig? {
        clocks.first { $0.id == id }
    }

    /// Returns false when no clock has this id.
    @discardableResult
    public func update(_ id: UUID, _ change: (inout ClockConfig) -> Void) -> Bool {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return false }
        change(&clocks[index])
        return true
    }

    @discardableResult
    public func add(_ clock: ClockConfig = ClockConfig(timeZoneID: TimeZone.gmt.identifier)) -> ClockConfig {
        clocks.append(clock)
        return clock
    }

    public func remove(id: UUID) {
        clocks.removeAll { $0.id == id }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(clocks) else { return }
        defaults.set(data, forKey: key)
    }
}
