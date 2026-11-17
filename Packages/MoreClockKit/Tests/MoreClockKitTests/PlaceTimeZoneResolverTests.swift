import Foundation
import Testing
@testable import MoreClockKit

@Suite("Place time zone identity")
struct PlaceTimeZoneResolverTests {
    @Test func hongKongKeepsItsOwnIdentifier() throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let resolved = try #require(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "HK"))
        #expect(resolved.identifier == "Asia/Hong_Kong")

        var clock = ClockConfig()
        clock.setTimeZone(.zone(resolved), placeName: "香港特别行政区")
        let saved = try JSONDecoder().decode(ClockConfig.self, from: JSONEncoder().encode(clock))
        #expect(saved.timeZoneID == "Asia/Hong_Kong")
        #expect(saved.placeName == "香港特别行政区")
    }

    @Test func actualHongKongMapsResponseUsesCNRegion() throws {
        // Reproduced through MKLocalSearchCompleter → MKLocalSearch with query "香港".
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let resolved = PlaceTimeZoneResolver.resolve(
            reportedZone: reported, regionCode: "CN", placeName: "香港特别行政区"
        )
        #expect(resolved?.identifier == "Asia/Hong_Kong")
    }

    @Test(arguments: ["香港", "香港特別行政區", "Hong Kong", "Hong Kong SAR", "Hong Kong Special Administrative Region"])
    func hongKongCityNames(_ placeName: String) throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "CN", placeName: placeName)?.identifier == "Asia/Hong_Kong")
    }

    @Test(arguments: ["澳门特别行政区", "澳門特別行政區", "Macau", "Macao SAR"])
    func macauCityNames(_ placeName: String) throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "CN", placeName: placeName)?.identifier == "Asia/Macau")
    }

    @Test(arguments: ["深圳市", "北京市", "Hong Kong Road", "Macao Street"])
    func mainlandCitiesAndStreetNamesAreNotRemapped(_ placeName: String) throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "CN", placeName: placeName)?.identifier == "Asia/Shanghai")
    }

    @Test func cityNameCannotOverrideAnUnrelatedRegion() throws {
        let reported = try #require(TimeZone(identifier: "America/New_York"))
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "US", placeName: "Hong Kong")?.identifier == "America/New_York")
    }

    @Test func macauKeepsItsOwnIdentifier() throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "MO")?.identifier == "Asia/Macau")
    }

    @Test func multiZoneRegionsPreserveMapsCoordinateBasedChoice() throws {
        for identifier in ["Asia/Shanghai", "Asia/Urumqi"] {
            let reported = try #require(TimeZone(identifier: identifier))
            #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "CN")?.identifier == identifier)
        }
        for identifier in ["America/New_York", "America/Los_Angeles", "Pacific/Honolulu"] {
            let reported = try #require(TimeZone(identifier: identifier))
            #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: "US")?.identifier == identifier)
        }
    }

    @Test func missingOrUnknownRegionLeavesReportedZoneAlone() throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        for region in [nil, "", "ZZ"] as [String?] {
            #expect(PlaceTimeZoneResolver.resolve(reportedZone: reported, regionCode: region)?.identifier == "Asia/Shanghai")
        }
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: nil, regionCode: nil) == nil)
    }

    @MainActor
    @Test func savedLegacyCityMismatchIsRepairedWithoutChangingOtherSettings() throws {
        let suite = "MoreClockPlaceMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let hongKong = ClockConfig(
            name: "Office", timeZoneID: "Asia/Shanghai", placeName: "香港特别行政区",
            prefix: "🇭🇰", showSeconds: true, dateDisplay: .weekdayAndDate, isBold: true
        )
        let macau = ClockConfig(timeZoneID: "Asia/Shanghai", placeName: "澳门特别行政区")
        let shenzhen = ClockConfig(timeZoneID: "Asia/Shanghai", placeName: "深圳市")
        let manuallyChosen = ClockConfig(name: "Hong Kong", timeZoneID: "Asia/Shanghai")
        defaults.set(try JSONEncoder().encode([hongKong, macau, shenzhen, manuallyChosen]), forKey: "clocks")

        let store = ClockStore(defaults: defaults)
        var expectedHongKong = hongKong
        expectedHongKong.timeZoneID = "Asia/Hong_Kong"
        var expectedMacau = macau
        expectedMacau.timeZoneID = "Asia/Macau"
        let expected = [expectedHongKong, expectedMacau, shenzhen, manuallyChosen]
        #expect(store.clocks == expected)
        let savedData = try #require(defaults.data(forKey: "clocks"))
        #expect(try JSONDecoder().decode([ClockConfig].self, from: savedData) == expected)
        #expect(ClockStore(defaults: defaults).clocks == expected) // Idempotent on subsequent launches.
    }

    @Test func singleZoneRegionDoesNotNeedAnOffsetGuess() {
        #expect(PlaceTimeZoneResolver.resolve(reportedZone: nil, regionCode: " hk ")?.identifier == "Asia/Hong_Kong")
    }
}
