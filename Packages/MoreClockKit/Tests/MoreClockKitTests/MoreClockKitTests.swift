import Foundation
import Testing
@testable import MoreClockKit

private func zone(_ input: String) throws -> TimeZone? {
    switch try TimeZoneSelection.parse(input) {
    case .system: nil
    case .zone(let zone): zone
    }
}

private let january = Date(timeIntervalSince1970: 1_768_467_907) // 2026-01-15 09:05:07 UTC

@Suite("Time zone parsing")
struct TimeZoneParsingTests {
    @Test(arguments: ["", "  ", "System", "system", "SYSTEM"])
    func systemInputs(_ input: String) throws {
        #expect(try TimeZoneSelection.parse(input) == .system)
    }

    @Test func wholeHourOffsetsMapToEtcZones() throws {
        #expect(try zone("GMT+5")?.identifier == "Etc/GMT-5")
        #expect(try zone("utc+14")?.identifier == "Etc/GMT-14")
        #expect(try zone("UTC-12")?.identifier == "Etc/GMT+12")
        #expect(try zone("UTC −3")?.identifier == "Etc/GMT+3") // Unicode minus sign
    }

    @Test func zeroOffsetIsGMT() throws {
        #expect(try zone("UTC+0") == .gmt)
        #expect(try zone("GMT-00:00") == .gmt)
    }

    @Test func halfHourOffsets() throws {
        #expect(try zone("UTC-3:30")?.secondsFromGMT(for: january) == -(3 * 3600 + 1800))
        #expect(try zone("UTC+0545")?.secondsFromGMT(for: january) == 5 * 3600 + 45 * 60)
    }

    @Test(arguments: ["UTC+5:75", "UTC-13", "UTC+15", "UTC+14:30", "garbage", "Mars/Olympus_Mons"])
    func rejectsInvalid(_ input: String) {
        #expect(throws: TimeZoneParseError.self) { try TimeZoneSelection.parse(input) }
    }

    @Test func identifiersAreCaseInsensitive() throws {
        #expect(try zone("America/Los_Angeles")?.identifier == "America/Los_Angeles")
        #expect(try zone("europe/oslo")?.identifier == "Europe/Oslo")
        #expect(try zone("UTC")?.secondsFromGMT(for: january) == 0)
    }

    @Test func abbreviations() throws {
        #expect(try zone("pst")?.secondsFromGMT(for: january) == -8 * 3600)
    }

    @Test func abbreviationsResolveToDSTAwareRegionsRegardlessOfCase() throws {
        for input in ["BST", "bst"] {
            #expect(try zone(input)?.secondsFromGMT(for: july) == 3600, "\(input) should be London, not Dhaka")
        }
        for input in ["EST", "est"] {
            #expect(try zone(input)?.secondsFromGMT(for: july) == -4 * 3600, "\(input) should observe DST")
        }
    }

    @Test func cityNames() throws {
        #expect(try zone("Tokyo")?.identifier == "Asia/Tokyo")
        #expect(try zone("new york")?.identifier == "America/New_York")
        #expect(try zone("Japan")?.secondsFromGMT(for: january) == 9 * 3600) // legacy link identifier
    }

    @Test(arguments: ["UTC+123", "UTC+5:3", "GMT+", "UTC+5:30:00"])
    func rejectsMalformedOffsets(_ input: String) {
        #expect(throws: TimeZoneParseError.self) { try TimeZoneSelection.parse(input) }
    }
}

private let july = Date(timeIntervalSince1970: 1_784_106_000) // 2026-07-15 09:00 UTC

@Suite("Labels")
struct LabelTests {
    @Test func offsetLabels() throws {
        #expect(TimeZone.gmt.offsetLabel(at: january) == "UTC")
        #expect(try #require(TimeZone(identifier: "Asia/Kolkata")).offsetLabel(at: january) == "UTC+5:30")
        #expect(try #require(TimeZone(identifier: "America/St_Johns")).offsetLabel(at: january) == "UTC-3:30")
        #expect(try #require(TimeZone(identifier: "Europe/Oslo")).displayLabel(at: january) == "Europe/Oslo (UTC+1)")
        #expect(try #require(TimeZone(identifier: "UTC")).displayLabel(at: january) == "UTC")
        #expect(TimeZone.gmt.displayLabel(at: january) == "UTC")
        #expect(try #require(TimeZone(identifier: "Etc/GMT-5")).displayLabel(at: january) == "UTC+5")
        #expect(try #require(TimeZone(secondsFromGMT: 19_800)).displayLabel(at: january) == "UTC+5:30")
    }

    @Test func defaultNamesComeFromThePlaceOrTheZone() throws {
        #expect(ClockConfig(timeZoneID: "Asia/Tokyo").displayName == "Tokyo")
        #expect(ClockConfig(timeZoneID: "America/Argentina/Buenos_Aires").displayName == "Buenos Aires")
        #expect(ClockConfig(timeZoneID: "UTC", prefix: "UTC").displayName == "UTC")
        #expect(ClockConfig(timeZoneID: "Etc/GMT-5").displayName == "UTC+5")
        #expect(ClockConfig().displayName == TimeZone.autoupdatingCurrent.cityName) // follows the system

        var kyoto = ClockConfig()
        kyoto.setTimeZone(.zone(try #require(TimeZone(identifier: "Asia/Tokyo"))), placeName: " 京都市 ")
        #expect(kyoto.displayName == "京都市")
        kyoto.selection = .zone(.gmt) // any other change forgets the place
        #expect(kyoto.placeName == nil)
        #expect(kyoto.displayName == "UTC")
    }

    @Test func customNameWins() {
        var clock = ClockConfig(name: "  Mom  ", timeZoneID: "Europe/Oslo")
        #expect(clock.displayName == "Mom")
        #expect(clock.defaultName == "Oslo")
        clock.name = "   "
        #expect(clock.displayName == "Oslo") // blank means "use the default"
    }

    @Test func searchIndexFoldsCaseAndDiacritics() {
        let index = TimeZoneSearchIndex(locale: Locale(identifier: "en_US"))
        #expect(index.matches(for: "SAO PAULO").map(\.identifier).contains("America/Sao_Paulo"))
        #expect(index.matches(for: "pacific time").map(\.identifier).contains("America/Los_Angeles"))
        #expect(index.matches(for: "a", limit: 5).count == 5)
    }

    @Test func relativeOffsets() throws {
        let oslo = try #require(TimeZone(identifier: "Europe/Oslo"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let kolkata = try #require(TimeZone(identifier: "Asia/Kolkata"))
        #expect(ClockFormatter.offsetDifference(of: tokyo, from: oslo, at: january) == 8 * 3600)
        #expect(ClockFormatter.offsetDifference(of: oslo, from: kolkata, at: january) == -(4 * 3600 + 1800))
        #expect(ClockFormatter.offsetDifference(of: oslo, from: oslo, at: january) == 0)
    }

    @Test func localSearchFindsCitiesAndNames() {
        #expect(TimeZone.localMatches(for: "tokyo").map(\.identifier).contains("Asia/Tokyo"))
        #expect(TimeZone.localMatches(for: "los angeles").map(\.identifier).contains("America/Los_Angeles"))
        #expect(TimeZone.localMatches(for: "UTC+5:30").first?.secondsFromGMT(for: january) == 19_800)
        #expect(TimeZone.localMatches(for: "").isEmpty)
    }
}

@Suite("Formatting")
struct FormattingTests {
    let us = Locale(identifier: "en_US")
    let gb = Locale(identifier: "en_GB")

    @Test func hourCycleFollowsLocale() {
        #expect(ClockFormatter.uses12HourClock(locale: us))
        #expect(!ClockFormatter.uses12HourClock(locale: gb))
    }

    @Test func twelveHour() {
        let s = ClockFormatter.timeString(for: january, timeZone: .gmt, showSeconds: false, locale: us)
        #expect(s.hasPrefix("9:05"))
        #expect(s.hasSuffix("AM"))
    }

    @Test func twentyFourHour() throws {
        #expect(ClockFormatter.timeString(for: january, timeZone: .gmt, showSeconds: false, locale: gb) == "09:05")
        #expect(ClockFormatter.timeString(for: january, timeZone: .gmt, showSeconds: true, locale: gb) == "09:05:07")
        let plus5 = try #require(TimeZone(identifier: "Etc/GMT-5"))
        #expect(ClockFormatter.timeString(for: january, timeZone: plus5, showSeconds: false, locale: gb) == "14:05")
    }

    @Test func dateParts() {
        // 2026-01-15 is a Thursday.
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .none, locale: us) == nil)
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .weekday, locale: us) == "Thu")
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .date, locale: us) == "Jan 15")
        let both = ClockFormatter.dateString(for: january, timeZone: .gmt, display: .weekdayAndDate, locale: us) ?? ""
        #expect(both.contains("Thu") && both.contains("Jan 15"))
    }

    @Test func datePartsAreLocalized() {
        let zh = Locale(identifier: "zh_Hans_CN")
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .weekday, locale: zh) == "周四")
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .date, locale: zh) == "1月15日")
        let de = ClockFormatter.dateString(for: january, timeZone: .gmt, display: .weekday, locale: Locale(identifier: "de_DE")) ?? ""
        #expect(de.hasPrefix("Do"))
    }

    @Test func rightToLeftLocales() {
        let ar = Locale(identifier: "ar")
        #expect(ClockFormatter.dateString(for: january, timeZone: .gmt, display: .weekday, locale: ar) == "خميس")

        // Persian: Solar Hijri calendar (15 Jan 2026 = 25 Dey 1404) and Persian digits.
        let fa = Locale(identifier: "fa_IR")
        let faDate = ClockFormatter.dateString(for: january, timeZone: .gmt, display: .date, locale: fa) ?? ""
        #expect(faDate.contains("دی"), "got \(faDate)")
        #expect(ClockFormatter.timeString(for: january, timeZone: .gmt, showSeconds: false, locale: fa).contains("۰۵"))
    }

    @Test func dateUsesTheClocksTimeZone() throws {
        // 09:05 UTC Thursday is still Wednesday in Honolulu (UTC-10) and already Thursday evening in Tokyo.
        let honolulu = try #require(TimeZone(identifier: "Pacific/Honolulu"))
        #expect(ClockFormatter.dateString(for: january, timeZone: honolulu, display: .weekday, locale: us) == "Wed")
        let clock = ClockConfig(timeZoneID: "Asia/Tokyo", prefix: "🇯🇵", dateDisplay: .weekday)
        #expect(ClockFormatter.title(for: january, config: clock, locale: gb) == "🇯🇵 Thu 18:05")
    }

    @Test func titleWithPrefix() {
        let clock = ClockConfig(timeZoneID: "UTC", prefix: "  🇬🇧 ")
        #expect(ClockFormatter.title(for: january, config: clock, locale: gb) == "🇬🇧 09:05")
        let bare = ClockConfig(timeZoneID: "UTC")
        #expect(ClockFormatter.title(for: january, config: bare, locale: gb) == "09:05")
    }
}

@Suite("Model and storage")
@MainActor
struct StoreTests {
    @Test func decodingFillsMissingKeys() throws {
        let json = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","prefix":"SF"}]"#
        let clocks = try JSONDecoder().decode([ClockConfig].self, from: Data(json.utf8))
        #expect(clocks.count == 1)
        #expect(clocks[0].prefix == "SF")
        #expect(clocks[0].timeZoneID == nil)
        #expect(clocks[0].isEnabled)
        #expect(clocks[0].name.isEmpty && clocks[0].placeName == nil)
        #expect(!clocks[0].showSeconds)
        #expect(clocks[0].dateDisplay == .none)
        #expect(!clocks[0].isBold)
    }

    @Test func unknownDateDisplayFallsBackWithoutLosingTheClock() throws {
        let json = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","prefix":"SF","dateDisplay":"fromTheFuture"},{"dateDisplay":"weekday"}]"#
        let clocks = try JSONDecoder().decode([ClockConfig].self, from: Data(json.utf8))
        #expect(clocks.map(\.dateDisplay) == [.none, .weekday])
        #expect(clocks[0].prefix == "SF")
    }

    @Test func boldRoundTrips() throws {
        let clock = ClockConfig(timeZoneID: "Asia/Tokyo", isBold: true)
        let decoded = try JSONDecoder().decode(ClockConfig.self, from: JSONEncoder().encode(clock))
        #expect(decoded.isBold)
        #expect(decoded == clock)
    }

    @Test func selectionRoundTrips() throws {
        var clock = ClockConfig()
        #expect(clock.selection == .system)
        let fixed = try #require(TimeZone(secondsFromGMT: 19_800))
        clock.selection = .zone(fixed)
        #expect(clock.timeZone.secondsFromGMT(for: january) == 19_800)
        clock.selection = .system
        #expect(clock.timeZoneID == nil)
    }

    @Test func unknownStoredIdentifierFallsBackToSystem() {
        let clock = ClockConfig(timeZoneID: "Nowhere/Gone")
        #expect(clock.selection == .system)
        #expect(clock.timeZone == .autoupdatingCurrent)
    }

    @Test func storePersistsOnlyAfterChange() throws {
        let suite = "MoreClockKitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ClockStore(defaults: defaults)
        #expect(store.clocks == ClockStore.defaultClocks)
        #expect(defaults.data(forKey: "clocks") == nil)

        let added = store.add(ClockConfig(timeZoneID: "Asia/Tokyo", prefix: "🇯🇵"))
        #expect(store.update(added.id) { $0.showSeconds = true })
        #expect(!store.update(UUID()) { $0.prefix = "x" })

        let reloaded = ClockStore(defaults: defaults)
        #expect(reloaded.clocks.count == 2)
        #expect(reloaded.clock(id: added.id)?.showSeconds == true)

        reloaded.remove(id: added.id)
        #expect(ClockStore(defaults: defaults).clocks == ClockStore.defaultClocks)
    }
}
