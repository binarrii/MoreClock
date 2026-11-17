import Foundation

/// Keeps a place's geographic IANA identifier when Maps returns an equivalent zone elsewhere.
public enum PlaceTimeZoneResolver {
    /// Explicit Hong Kong/Macau city identities take precedence when Maps groups them under CN.
    /// Otherwise, regions with one IANA zone use that identifier, and multi-zone regions retain
    /// Maps' coordinate-based result. Today's UTC offset alone never chooses another zone.
    public static func resolve(reportedZone: TimeZone?, regionCode: String?, placeName: String? = nil) -> TimeZone? {
        var region = regionCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""

        // Maps can report CN and Asia/Shanghai for the city 香港特别行政区 itself.
        // An exact city identity must take precedence over that broader region code.
        if let placeName, let placeRegion = specialAdministrativeRegion(named: placeName),
           region.isEmpty || region == "CN" || region == placeRegion {
            region = placeRegion
        }

        guard let identifiers = identifiersByRegion[region], identifiers.count == 1,
              let identifier = identifiers.first, let zone = TimeZone(identifier: identifier)
        else { return reportedZone }
        return zone
    }

    /// A default flag for the zone's ISO region, when that identity is unambiguous.
    /// Fixed UTC offsets have no country. Prefer the resolved zone over Maps' broader region
    /// metadata so Asia/Hong_Kong produces 🇭🇰 even when Maps returned CN.
    public static func defaultFlag(for zone: TimeZone) -> String? {
        let regions = identifiersByRegion.compactMap { region, identifiers in
            identifiers.contains(zone.identifier) ? region : nil
        }
        guard regions.count == 1, let region = regions.first,
              region.unicodeScalars.count == 2,
              region.unicodeScalars.allSatisfy({ (65...90).contains($0.value) })
        else { return nil }

        let indicators = region.unicodeScalars.compactMap { UnicodeScalar(0x1F1E6 + $0.value - 65) }
        return String(String.UnicodeScalarView(indicators))
    }

    private static func specialAdministrativeRegion(named placeName: String) -> String? {
        let name = normalized(placeName)
        guard !name.isEmpty else { return nil }
        let aliases: [(region: String, identifier: String, names: [String])] = [
            ("HK", "Asia/Hong_Kong", [
                "Hong Kong", "Hong Kong SAR", "Hong Kong Special Administrative Region",
                "香港", "香港特别行政区", "香港特別行政區",
            ]),
            ("MO", "Asia/Macau", [
                "Macau", "Macao", "Macau SAR", "Macao SAR",
                "Macau Special Administrative Region", "Macao Special Administrative Region",
                "澳门", "澳門", "澳门特别行政区", "澳門特別行政區",
            ]),
        ]

        for entry in aliases {
            if entry.names.contains(where: { normalized($0) == name }) { return entry.region }

            // Include native localized city and region names, such as هونغ كونغ or هنگ‌کنگ.
            let locale = Locale.autoupdatingCurrent
            if let regionName = locale.localizedString(forRegionCode: entry.region),
               normalized(regionName) == name { return entry.region }
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = TimeZone(identifier: entry.identifier)
            formatter.dateFormat = "VVV" // ICU exemplar city; not the current UTC offset.
            if normalized(formatter.string(from: Date(timeIntervalSinceReferenceDate: 0))) == name {
                return entry.region
            }
        }
        return nil
    }

    private static func normalized(_ name: String) -> String {
        // Exact normalized matches only: a street merely containing “Hong Kong” isn't the city.
        name.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined()
    }

    private static let identifiersByRegion: [String: [String]] = {
        guard let url = Bundle.module.url(forResource: "zone", withExtension: "tab"),
              let table = try? String(contentsOf: url, encoding: .utf8)
        else { return [:] }

        // zone.tab retains a separate entry for each ISO region. We need that geographic
        // identity rather than grouping regions whose civil-time histories agree.
        var result: [String: [String]] = [:]
        for line in table.split(separator: "\n") where !line.hasPrefix("#") {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count >= 3 else { continue }
            result[String(fields[0]), default: []].append(String(fields[2]))
        }
        return result
    }()
}
