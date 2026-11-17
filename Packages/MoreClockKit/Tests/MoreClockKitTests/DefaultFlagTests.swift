import Foundation
import Testing
@testable import MoreClockKit

@Suite("Default flag prefix")
struct DefaultFlagTests {
    @Test(arguments: [
        ("Asia/Hong_Kong", "🇭🇰"),
        ("Asia/Macau", "🇲🇴"),
        ("Asia/Shanghai", "🇨🇳"),
        ("Asia/Tokyo", "🇯🇵"),
        ("America/New_York", "🇺🇸"),
        ("Europe/London", "🇬🇧"),
    ])
    func zoneUsesItsOwnRegion(_ identifier: String, _ expectedFlag: String) throws {
        let zone = try #require(TimeZone(identifier: identifier))
        #expect(PlaceTimeZoneResolver.defaultFlag(for: zone) == expectedFlag)
    }

    @Test func choosingAPlaceFillsAnEmptyPrefix() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        var clock = ClockConfig()
        clock.setTimeZone(.zone(tokyo), placeName: "東京都")
        #expect(clock.prefix == "🇯🇵")
        #expect(clock.timeZoneID == "Asia/Tokyo")
        #expect(clock.placeName == "東京都")
    }

    @Test func whitespaceOnlyPrefixIsEmpty() throws {
        var clock = ClockConfig(prefix: " \n ")
        clock.selection = .zone(try #require(TimeZone(identifier: "Europe/London")))
        #expect(clock.prefix == "🇬🇧")
    }

    @Test(arguments: ["Office", "🇺🇸", " 🇭🇰 HK "])
    func existingPrefixIsPreserved(_ prefix: String) throws {
        var clock = ClockConfig(prefix: prefix)
        clock.setTimeZone(.zone(try #require(TimeZone(identifier: "Asia/Tokyo"))), placeName: "Tokyo")
        #expect(clock.prefix == prefix)
    }

    @Test func hongKongUsesTheCorrectedZoneRatherThanMapsCNRegion() throws {
        let reported = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let resolved = try #require(PlaceTimeZoneResolver.resolve(
            reportedZone: reported, regionCode: "CN", placeName: "香港特别行政区"
        ))
        var clock = ClockConfig()
        clock.setTimeZone(.zone(resolved), placeName: "香港特别行政区")
        #expect(clock.prefix == "🇭🇰")
        #expect(clock.timeZoneID == "Asia/Hong_Kong")
        let saved = try JSONDecoder().decode(ClockConfig.self, from: JSONEncoder().encode(clock))
        #expect(saved == clock)
    }

    @Test func utcAndFixedOffsetsHaveNoCountryFlag() throws {
        #expect(PlaceTimeZoneResolver.defaultFlag(for: .gmt) == nil)
        let offset = try #require(TimeZone(secondsFromGMT: 19_800))
        var clock = ClockConfig()
        clock.selection = .zone(offset)
        #expect(clock.prefix.isEmpty)
        clock.selection = .zone(.gmt)
        #expect(clock.prefix.isEmpty)
    }
}
