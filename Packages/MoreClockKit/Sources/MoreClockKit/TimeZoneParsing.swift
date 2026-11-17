import Foundation

public struct TimeZoneParseError: Error, Equatable, Sendable {
    public let input: String
}

extension TimeZoneSelection {
    /// Parses free text as typed or spoken in Shortcuts, or typed in the picker's search field.
    ///
    /// Accepts:
    /// - "" or "System" (any case) → `.system`
    /// - "UTC+5", "gmt-3", "UTC+5:30", "UTC-0330" → fixed offset, from -12:00 to +14:00
    /// - abbreviations: "PST", "BST", "CET". These resolve to the region's DST-aware zone, such as Europe/London.
    /// - IANA identifiers, any case: "America/Los_Angeles", "europe/oslo"
    /// - city names matching an identifier's last part: "Tokyo", "new york"
    public static func parse(_ raw: String) throws(TimeZoneParseError) -> TimeZoneSelection {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty || s.caseInsensitiveCompare("system") == .orderedSame { return .system }

        // Offsets come first. TimeZone(identifier:) also accepts "GMT+5", so checking it
        // first would give different zones depending on the spelling.
        if let zone = try parseOffset(s, raw: raw) { return .zone(zone) }

        // Abbreviations come before identifiers: TimeZone(identifier: "BST") is Bangladesh
        // and "EST" is a fixed -5 without DST, while the abbreviation table maps them to
        // Europe/London and America/New_York.
        if s.count <= 5, s.allSatisfy(\.isLetter), let zone = TimeZone(abbreviation: s.uppercased()) {
            return .zone(zone)
        }

        let known = TimeZone.knownTimeZoneIdentifiers
        if let id = known.first(where: { $0.caseInsensitiveCompare(s) == .orderedSame }),
           let zone = TimeZone(identifier: id) {
            return .zone(zone)
        }
        if let zone = TimeZone(identifier: s) { return .zone(zone) } // "GMT", "UTC", legacy links such as "Japan"

        let city = s.replacingOccurrences(of: " ", with: "_")
        if let id = known.first(where: { $0.split(separator: "/").last?.caseInsensitiveCompare(city) == .orderedSame }),
           let zone = TimeZone(identifier: id) {
            return .zone(zone)
        }
        throw TimeZoneParseError(input: raw)
    }

    /// Returns `nil` when `s` doesn't look like an offset. Throws when it looks like one but is malformed or out of range.
    private static func parseOffset(_ s: String, raw: String) throws(TimeZoneParseError) -> TimeZone? {
        guard s.wholeMatch(of: /^(?:UTC|GMT)\s*[+\-−].*$/.ignoresCase()) != nil else { return nil }

        let compact = /^(?:UTC|GMT)\s*([+\-−])\s*(\d{2})(\d{2})$/.ignoresCase()       // UTC+0530
        let separated = /^(?:UTC|GMT)\s*([+\-−])\s*(\d{1,2})(?::(\d{2}))?$/.ignoresCase() // UTC+5, UTC+5:30
        let parts: (sign: Substring, hours: Substring, minutes: Substring?)
        if let m = s.wholeMatch(of: compact) {
            parts = (m.1, m.2, m.3)
        } else if let m = s.wholeMatch(of: separated) {
            parts = (m.1, m.2, m.3)
        } else {
            throw TimeZoneParseError(input: raw)
        }

        guard let hours = Int(parts.hours), let minutes = Int(parts.minutes ?? "0"), minutes < 60 else {
            throw TimeZoneParseError(input: raw)
        }
        let sign = parts.sign == "+" ? 1 : -1
        let total = sign * (hours * 3600 + minutes * 60)
        guard (-12 * 3600)...(14 * 3600) ~= total else { throw TimeZoneParseError(input: raw) }

        if total == 0 { return .gmt }
        // Whole hours map to the named Etc zones. Their sign is inverted by POSIX convention:
        // UTC+5 is "Etc/GMT-5".
        if minutes == 0, let etc = TimeZone(identifier: "Etc/GMT\(sign > 0 ? "-" : "+")\(hours)") {
            return etc
        }
        guard let fixed = TimeZone(secondsFromGMT: total) else { throw TimeZoneParseError(input: raw) }
        return fixed
    }
}

extension TimeZone {
    /// "UTC", "UTC+1", "UTC-3:30" for the offset in effect at `date`.
    public func offsetLabel(at date: Date = .now) -> String {
        let seconds = secondsFromGMT(for: date)
        guard seconds != 0 else { return "UTC" }
        let sign = seconds < 0 ? "-" : "+"
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        return minutes == 0 ? "UTC\(sign)\(hours)" : "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
    }

    /// True for zones that are only an offset, with no region and no DST: "GMT", "Etc/GMT-5", "GMT+0530".
    public var isFixedOffset: Bool {
        identifier == "UTC" || identifier.hasPrefix("GMT") || identifier.hasPrefix("Etc/")
    }

    /// The city part of the identifier ("Asia/Tokyo" → "Tokyo", "America/Argentina/Buenos_Aires" →
    /// "Buenos Aires"), or the offset label for fixed-offset zones ("UTC", "UTC+5").
    public var cityName: String {
        if isFixedOffset { return offsetLabel() }
        let last = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return last.replacingOccurrences(of: "_", with: " ")
    }

    /// "Europe/Oslo (UTC+1)". Fixed-offset zones show just the offset ("UTC+5", "UTC").
    /// That avoids the POSIX-inverted "Etc/GMT-5" and Foundation reporting "UTC" as "GMT".
    public func displayLabel(at date: Date = .now) -> String {
        if isFixedOffset { return offsetLabel(at: date) }
        return "\(identifier) (\(offsetLabel(at: date)))"
    }

    /// Offline matches for a search query. Builds a new index; reuse a `TimeZoneSearchIndex` when searching repeatedly.
    public static func localMatches(for query: String, locale: Locale = .autoupdatingCurrent, limit: Int = 40) -> [TimeZone] {
        TimeZoneSearchIndex(locale: locale).matches(for: query, limit: limit)
    }
}

/// A precomputed, case- and diacritic-folded index of every known time zone's identifier
/// and localized generic name ("Pacific Time"). Building it takes a few tens of
/// milliseconds; each search is a plain substring scan.
public struct TimeZoneSearchIndex: Sendable {
    private struct Entry: Sendable {
        let zone: TimeZone
        let haystack: String
    }

    private let entries: [Entry]

    public init(locale: Locale = .autoupdatingCurrent) {
        entries = TimeZone.knownTimeZoneIdentifiers.compactMap { id in
            guard let zone = TimeZone(identifier: id) else { return nil }
            let readable = id.replacingOccurrences(of: "_", with: " ")
            let name = zone.localizedName(for: .generic, locale: locale) ?? ""
            return Entry(zone: zone, haystack: Self.fold("\(readable)\n\(name)"))
        }
    }

    /// The parsed zone, if the query parses as one (an offset, abbreviation or city), comes first.
    public func matches(for query: String, limit: Int = 40) -> [TimeZone] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        var results: [TimeZone] = []
        if case .zone(let parsed)? = try? TimeZoneSelection.parse(q) { results.append(parsed) }

        let needle = Self.fold(q)
        for entry in entries where results.count < limit {
            if entry.haystack.contains(needle), !results.contains(entry.zone) {
                results.append(entry.zone)
            }
        }
        return results
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}
