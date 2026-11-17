import Foundation

public enum ClockFormatter {
    /// True when the locale, including the user's "24-hour time" choice in System Settings, uses a 12-hour clock.
    public static func uses12HourClock(locale: Locale) -> Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)?.contains("a") ?? false
    }

    /// "9:05 AM" or "09:05", plus ":07" when `showSeconds` is on.
    public static func timeString(
        for date: Date,
        timeZone: TimeZone,
        showSeconds: Bool,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let hour: Date.FormatStyle.Symbol.Hour = uses12HourClock(locale: locale)
            ? .defaultDigits(amPM: .abbreviated)
            : .twoDigits(amPM: .omitted)
        var style = Date.FormatStyle(locale: locale, calendar: locale.calendar, timeZone: timeZone).hour(hour).minute(.twoDigits)
        if showSeconds { style = style.second(.twoDigits) }
        return date.formatted(style)
    }

    /// The date part of a clock in its own time zone, formatted for `locale`:
    /// "Tue", "Nov 17", "Tue, Nov 17" (en_US); "周二", "11月17日" (zh_Hans). `nil` for `.none`.
    public static func dateString(
        for date: Date,
        timeZone: TimeZone,
        display: DateDisplay,
        locale: Locale = .autoupdatingCurrent
    ) -> String? {
        // The calendar comes from the locale, which carries the user's calendar choice (Gregorian,
        // Solar Hijri, Buddhist…) for `.autoupdatingCurrent`.
        let base = Date.FormatStyle(locale: locale, calendar: locale.calendar, timeZone: timeZone)
        let style: Date.FormatStyle
        switch display {
        case .none: return nil
        case .weekday: style = base.weekday(.abbreviated)
        case .date: style = base.month(.abbreviated).day()
        case .weekdayAndDate: style = base.weekday(.abbreviated).month(.abbreviated).day()
        }
        return date.formatted(style)
    }

    /// The menu bar title: prefix, then the optional date, then the time, separated by spaces.
    public static func title(for date: Date, config: ClockConfig, locale: Locale = .autoupdatingCurrent) -> String {
        let prefix = config.prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let day = dateString(for: date, timeZone: config.timeZone, display: config.dateDisplay, locale: locale)
        let time = timeString(for: date, timeZone: config.timeZone, showSeconds: config.showSeconds, locale: locale)
        return [prefix, day ?? "", time].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Menu header line, e.g. "Thursday, 15 Jan, 18:05".
    public static func longString(for date: Date, timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, calendar: locale.calendar, timeZone: timeZone)
                .weekday(.wide).day().month(.abbreviated).hour().minute()
        )
    }

    /// Seconds that `zone` is ahead of `reference` (negative when behind), using each zone's offset at `date`.
    public static func offsetDifference(of zone: TimeZone, from reference: TimeZone, at date: Date = .now) -> Int {
        zone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
    }
}
