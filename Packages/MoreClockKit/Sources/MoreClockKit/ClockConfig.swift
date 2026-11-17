import Foundation

/// One menu bar clock.
public struct ClockConfig: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    /// The user's own name for the clock, such as "Mom" or "Tokyo office". Empty means `defaultName`.
    public var name: String
    /// An IANA identifier ("Asia/Tokyo") or a fixed-offset identifier ("GMT+0530").
    /// `nil` follows the system time zone.
    public var timeZoneID: String?
    /// The place picked in the time zone search ("Kyoto"), in the language Maps returned it.
    /// Cleared whenever the time zone is changed any other way.
    public var placeName: String?
    /// Text shown before the time, such as a flag emoji or "SF".
    public var prefix: String
    public var showSeconds: Bool
    /// Optional weekday and/or date shown before the time.
    public var dateDisplay: DateDisplay
    /// Draws the menu bar text in bold.
    public var isBold: Bool
    /// Whether the clock is shown in the menu bar.
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String = "",
        timeZoneID: String? = nil,
        placeName: String? = nil,
        prefix: String = "",
        showSeconds: Bool = false,
        dateDisplay: DateDisplay = .none,
        isBold: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.timeZoneID = timeZoneID
        self.placeName = placeName
        self.prefix = prefix
        self.showSeconds = showSeconds
        self.dateDisplay = dateDisplay
        self.isBold = isBold
        self.isEnabled = isEnabled
    }

    /// The time zone to display. An unknown stored identifier falls back to the system time zone.
    public var timeZone: TimeZone {
        timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .autoupdatingCurrent
    }

    public var selection: TimeZoneSelection {
        get {
            guard let timeZoneID, let zone = TimeZone(identifier: timeZoneID) else { return .system }
            return .zone(zone)
        }
        set { setTimeZone(newValue, placeName: nil) }
    }

    /// Changes the time zone, records the selected place, and fills an empty prefix with its flag.
    /// An existing prefix is preserved. Fixed offsets without a region have no default flag.
    public mutating func setTimeZone(_ selection: TimeZoneSelection, placeName: String?) {
        switch selection {
        case .system: timeZoneID = nil
        case .zone(let zone): timeZoneID = zone.identifier
        }
        let trimmed = placeName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.placeName = trimmed?.isEmpty == false ? trimmed : nil
        if prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let flag = PlaceTimeZoneResolver.defaultFlag(for: timeZone) {
            prefix = flag
        }
    }

    /// The name used when the user hasn't set one: the picked place, otherwise the time zone's
    /// city ("Tokyo", "Los Angeles"), or the offset for fixed-offset zones ("UTC+5").
    /// A clock following the system uses the Mac's current city.
    public var defaultName: String {
        placeName ?? timeZone.cityName
    }

    /// The custom name if set, otherwise `defaultName`. Used in Settings, the clock's menu and Shortcuts.
    public var displayName: String {
        let custom = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? defaultName : custom
    }

    // Missing keys decode to defaults, so adding a field later never wipes saved clocks.
    private enum CodingKeys: String, CodingKey {
        case id, name, timeZoneID, placeName, prefix, showSeconds, dateDisplay, isBold, isEnabled
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        timeZoneID = try c.decodeIfPresent(String.self, forKey: .timeZoneID)
        placeName = try c.decodeIfPresent(String.self, forKey: .placeName)
        prefix = try c.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        showSeconds = try c.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? false
        // `try?`: an unknown value written by a newer version falls back instead of failing the whole list.
        dateDisplay = (try? c.decodeIfPresent(DateDisplay.self, forKey: .dateDisplay)) ?? .none
        isBold = try c.decodeIfPresent(Bool.self, forKey: .isBold) ?? false
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}

/// What part of the date, if any, a clock shows before the time.
public enum DateDisplay: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case weekdayAndDate   // "Tue, Nov 17"
    case date             // "Nov 17"
    case weekday          // "Tue"
}

public enum TimeZoneSelection: Hashable, Sendable {
    case system
    case zone(TimeZone)

    public var timeZone: TimeZone {
        switch self {
        case .system: .autoupdatingCurrent
        case .zone(let zone): zone
        }
    }
}
