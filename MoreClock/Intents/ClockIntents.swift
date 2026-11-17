import AppIntents
import Foundation
import MoreClockKit

// Every intent runs in the app's process (`openAppWhenRun` is false), writes through
// `ClockStore.shared`, and the menu bar updates straight away through Observation.

// MARK: Entity

struct ClockEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Clock" }
    static var defaultQuery: ClockQuery { ClockQuery() }

    let id: UUID
    let name: String
    let zone: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(zone)")
    }

    init(_ clock: ClockConfig) {
        id = clock.id
        name = clock.displayName
        zone = clock.timeZone.displayLabel()
    }
}

struct ClockQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [ClockEntity.ID]) async throws -> [ClockEntity] {
        ClockStore.shared.clocks.filter { identifiers.contains($0.id) }.map(ClockEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ClockEntity] {
        ClockStore.shared.clocks.map(ClockEntity.init)
    }
}

// MARK: Errors and options

enum ClockIntentError: Error, CustomLocalizedStringResourceConvertible {
    case clockNotFound
    case invalidTimeZone(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .clockNotFound:
            "That clock no longer exists."
        case .invalidTimeZone(let input):
            "“\(input)” is not a time zone. Use an identifier such as “America/Los_Angeles”, an offset such as “UTC+5:30”, or “System”."
        }
    }
}

struct TimeZoneOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        ["System", "UTC"] + TimeZone.knownTimeZoneIdentifiers
    }
}

@MainActor
private func parseTimeZone(_ input: String) throws -> TimeZoneSelection {
    do {
        return try TimeZoneSelection.parse(input)
    } catch {
        throw ClockIntentError.invalidTimeZone(input)
    }
}

@MainActor
private func update(_ clock: ClockEntity, _ change: (inout ClockConfig) -> Void) throws {
    guard ClockStore.shared.update(clock.id, change) else { throw ClockIntentError.clockNotFound }
}

// MARK: Intents

struct SetClockTimeZoneIntent: AppIntent {
    static var title: LocalizedStringResource { "Set Clock Time Zone" }
    static var description: IntentDescription {
        IntentDescription("Changes the time zone of a MoreClock clock. Accepts an identifier such as “Asia/Tokyo”, an offset such as “UTC+5:30”, or “System”.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity
    @Parameter(title: "Time Zone", optionsProvider: TimeZoneOptionsProvider()) var timeZone: String

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$clock) to \(\.$timeZone)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let selection = try parseTimeZone(timeZone)
        try update(clock) { $0.selection = selection }
        return .result()
    }
}

struct GetClockTimeZoneIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Clock Time Zone" }
    static var description: IntentDescription {
        IntentDescription("Returns the clock’s time zone identifier, or “System” when it follows the system time zone. The result can be passed straight to “Set Clock Time Zone”.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the time zone of \(\.$clock)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let config = ClockStore.shared.clock(id: clock.id) else { throw ClockIntentError.clockNotFound }
        return .result(value: config.timeZoneID == nil ? "System" : config.timeZone.identifier)
    }
}

struct SetClockNameIntent: AppIntent {
    static var title: LocalizedStringResource { "Set Clock Name" }
    static var description: IntentDescription {
        IntentDescription("Renames a clock. Leave the name empty to use the city or time zone name.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity
    @Parameter(title: "Name") var name: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Rename \(\.$clock) to \(\.$name)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try update(clock) { $0.name = name ?? "" }
        return .result()
    }
}

struct SetClockPrefixIntent: AppIntent {
    static var title: LocalizedStringResource { "Set Clock Prefix" }
    static var description: IntentDescription {
        IntentDescription("Sets the text shown before the time. Leave it empty to clear the prefix.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity
    @Parameter(title: "Prefix", inputOptions: String.IntentInputOptions(capitalizationType: .none, autocorrect: false, smartQuotes: false, smartDashes: false))
    var prefix: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Set the prefix of \(\.$clock) to \(\.$prefix)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try update(clock) { $0.prefix = prefix ?? "" }
        return .result()
    }
}

struct SetClockVisibilityIntent: AppIntent {
    static var title: LocalizedStringResource { "Show or Hide Clock" }
    static var description: IntentDescription {
        IntentDescription("Shows or hides a clock in the menu bar. Useful in Focus automations.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity
    @Parameter(title: "Show", default: true) var isShown: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Show or hide \(\.$clock)") {
            \.$isShown
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try update(clock) { $0.isEnabled = isShown }
        return .result()
    }
}

/// App Intents only accepts enums declared in the app module, so this mirrors `DateDisplay`.
enum DateDisplayOption: String, AppEnum {
    case none, weekdayAndDate, date, weekday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Date Display"
    static let caseDisplayRepresentations: [DateDisplayOption: DisplayRepresentation] = [
        .none: "Off",
        .weekdayAndDate: "Weekday and Date",
        .date: "Date",
        .weekday: "Weekday",
    ]

    var dateDisplay: DateDisplay {
        switch self {
        case .none: .none
        case .weekday: .weekday
        case .date: .date
        case .weekdayAndDate: .weekdayAndDate
        }
    }
}

struct SetClockDateDisplayIntent: AppIntent {
    static var title: LocalizedStringResource { "Set Clock Date Display" }
    static var description: IntentDescription {
        IntentDescription("Chooses whether a clock shows the weekday, the date, both, or neither before the time.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity
    @Parameter(title: "Date Display", default: .weekday) var display: DateDisplayOption

    static var parameterSummary: some ParameterSummary {
        Summary("Set the date display of \(\.$clock) to \(\.$display)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try update(clock) { $0.dateDisplay = display.dateDisplay }
        return .result()
    }
}

struct GetClockTimeIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Clock Time" }
    static var description: IntentDescription {
        IntentDescription("Returns the current time of a clock, formatted as it appears in the menu bar.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the time of \(\.$clock)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let config = ClockStore.shared.clock(id: clock.id) else { throw ClockIntentError.clockNotFound }
        return .result(value: ClockFormatter.timeString(for: .now, timeZone: config.timeZone, showSeconds: config.showSeconds))
    }
}

struct AddClockIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Clock" }
    static var description: IntentDescription {
        IntentDescription("Adds a clock to the menu bar.")
    }

    @Parameter(title: "Time Zone", optionsProvider: TimeZoneOptionsProvider()) var timeZone: String
    @Parameter(title: "Name") var name: String?
    @Parameter(title: "Prefix") var prefix: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add a clock for \(\.$timeZone)") {
            \.$name
            \.$prefix
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ClockEntity> {
        var config = ClockConfig(name: name ?? "", prefix: prefix ?? "")
        config.selection = try parseTimeZone(timeZone)
        ClockStore.shared.add(config)
        return .result(value: ClockEntity(config))
    }
}

struct RemoveClockIntent: AppIntent {
    static var title: LocalizedStringResource { "Remove Clock" }
    static var description: IntentDescription {
        IntentDescription("Removes a clock from MoreClock.")
    }

    @Parameter(title: "Clock") var clock: ClockEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$clock)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard ClockStore.shared.clock(id: clock.id) != nil else { throw ClockIntentError.clockNotFound }
        ClockStore.shared.remove(id: clock.id)
        return .result()
    }
}

// MARK: App Shortcuts

struct MoreClockShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddClockIntent(),
            phrases: ["Add a clock in \(.applicationName)"],
            shortTitle: "Add Clock",
            systemImageName: "clock.badge.plus"
        )
        AppShortcut(
            intent: GetClockTimeIntent(),
            phrases: [
                "What time is it on \(\.$clock) in \(.applicationName)",
                "Get a clock time in \(.applicationName)",
            ],
            shortTitle: "Get Clock Time",
            systemImageName: "clock"
        )
    }
}

