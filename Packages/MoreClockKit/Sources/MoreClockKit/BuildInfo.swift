import Foundation

/// Version details shown in Settings › About.
///
/// The marketing version and build number are standard bundle keys. The commit and build
/// time are written into Info.plist by `Scripts/build-release.sh`. Builds made without that
/// script (for example from Xcode) leave them empty and only show the version.
public struct BuildInfo: Equatable, Sendable {
    public static let commitKey = "MoreClockGitCommit"
    public static let buildDateKey = "MoreClockBuildDate"

    public let version: String
    public let build: String
    public let commit: String?
    public let buildDate: Date?

    public init(infoDictionary: [String: Any]) {
        version = Self.text(infoDictionary["CFBundleShortVersionString"]) ?? "?"
        build = Self.text(infoDictionary["CFBundleVersion"]) ?? "?"
        commit = Self.text(infoDictionary[Self.commitKey])
        buildDate = Self.text(infoDictionary[Self.buildDateKey]).flatMap { try? Date($0, strategy: .iso8601) }
    }

    /// "v0.1.1 (23d0745) 2026-11-17 17:55", in the given time zone. `nil` when the build
    /// carries no commit, so development builds don't show made-up provenance.
    public func detail(timeZone: TimeZone = .autoupdatingCurrent) -> String? {
        guard let commit else { return nil }
        var parts = ["v\(version)", "(\(commit))"]
        if let buildDate {
            let style = Date.VerbatimFormatStyle(
                format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
                timeZone: timeZone,
                calendar: Calendar(identifier: .gregorian)
            )
            parts.append(buildDate.formatted(style))
        }
        return parts.joined(separator: " ")
    }

    private static func text(_ value: Any?) -> String? {
        guard let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else { return nil }
        return string
    }
}
