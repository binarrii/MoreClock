import Foundation
import Testing
@testable import MoreClockKit

@Suite("Build info")
struct BuildInfoTests {
    @Test func releaseBuildShowsVersionCommitAndTime() throws {
        let info = BuildInfo(infoDictionary: [
            "CFBundleShortVersionString": "0.1.1",
            "CFBundleVersion": "7",
            BuildInfo.commitKey: "23d0745",
            BuildInfo.buildDateKey: "2026-11-17T09:55:00Z",
        ])
        #expect(info.version == "0.1.1")
        #expect(info.build == "7")
        #expect(info.detail(timeZone: .gmt) == "v0.1.1 (23d0745) 2026-11-17 09:55")
        let shanghai = try #require(TimeZone(identifier: "Asia/Shanghai"))
        #expect(info.detail(timeZone: shanghai) == "v0.1.1 (23d0745) 2026-11-17 17:55")
    }

    @Test func buildTimeUsesASCIIDigitsAndGregorianCalendarEverywhere() {
        // The detail line is a technical stamp, like a commit hash, not localized prose.
        let info = BuildInfo(infoDictionary: [
            "CFBundleShortVersionString": "0.1.1", "CFBundleVersion": "7",
            BuildInfo.commitKey: "abc1234", BuildInfo.buildDateKey: "2026-01-05T03:04:00Z",
        ])
        #expect(info.detail(timeZone: .gmt) == "v0.1.1 (abc1234) 2026-01-05 03:04")
    }

    @Test(arguments: [[:], [BuildInfo.commitKey: ""], [BuildInfo.commitKey: "  "]] as [[String: String]])
    func developmentBuildsHaveNoDetailLine(_ extra: [String: String]) {
        var dictionary: [String: Any] = ["CFBundleShortVersionString": "0.1.1", "CFBundleVersion": "7"]
        dictionary.merge(extra) { $1 }
        #expect(BuildInfo(infoDictionary: dictionary).detail() == nil)
    }

    @Test func commitWithoutValidDateOmitsTheTime() {
        let info = BuildInfo(infoDictionary: [
            "CFBundleShortVersionString": "0.1.1", "CFBundleVersion": "7",
            BuildInfo.commitKey: "23d0745-dirty", BuildInfo.buildDateKey: "not a date",
        ])
        #expect(info.buildDate == nil)
        #expect(info.detail(timeZone: .gmt) == "v0.1.1 (23d0745-dirty)")
    }

    @Test func missingVersionKeysAreVisibleRatherThanBlank() {
        let info = BuildInfo(infoDictionary: [:])
        #expect(info.version == "?" && info.build == "?")
    }
}
