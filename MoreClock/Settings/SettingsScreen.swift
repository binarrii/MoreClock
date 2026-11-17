import AppKit
import MoreClockKit
import ServiceManagement
import SwiftUI

/// Settings › General: app-wide options and help.
struct GeneralSettingsView: View {
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)
                if launchAtLogin.needsApproval {
                    LabeledContent {
                        Button("Open Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                    } label: {
                        Text("Approval needed")
                        Text("Allow MoreClock in System Settings › General › Login Items & Extensions.")
                    }
                }
            }

            Section {
                LabeledContent {
                    Button("Open Date & Time…") { open("x-apple.systempreferences:com.apple.Date-Time-Settings.extension") }
                } label: {
                    Text("12- or 24-hour time")
                    Text("MoreClock follows the “24-hour time” setting in System Settings.")
                }
                LabeledContent {
                    Button("Open Menu Bar…") { open("x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") }
                } label: {
                    Text("Clock not showing?")
                    Text("Make sure MoreClock is allowed in the menu bar, and that the notch or other items aren’t covering it.")
                }
            }

            LanguageSetting()
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 380) // Remains scrollable when translations or approval messages need more space.
        .onAppear { launchAtLogin.refresh() }
        // The user may approve or remove the login item in System Settings, then switch back.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLogin.refresh()
        }
        .alert(
            "Launch at Login",
            isPresented: Binding(
                get: { launchAtLogin.errorMessage != nil },
                set: { if !$0 { launchAtLogin.errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(launchAtLogin.errorMessage ?? "")
        }
    }

    private func open(_ url: String) {
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
}

/// Settings › Clocks: one collapsible section per clock, plus Add Clock.
struct ClocksSettingsView: View {
    private let store = ClockStore.shared
    /// Only the first clock starts expanded, so a long list stays scannable.
    @State private var expandedClocks: Set<UUID> = Set(ClockStore.shared.clocks.prefix(1).map(\.id))

    var body: some View {
        Form {
            ForEach(store.clocks) { clock in
                ClockSection(clock: binding(for: clock), isExpanded: expansionBinding(for: clock.id)) {
                    expandedClocks.remove(clock.id)
                    store.remove(id: clock.id)
                }
            }

            Section {
                Button("Add Clock", systemImage: "plus") {
                    let clock = store.add()
                    expandedClocks.insert(clock.id) // a new clock opens ready to set up
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hold ⌘ and drag a clock to move it in the menu bar. Drag it out of the menu bar to hide it.")
                    if !store.clocks.contains(where: \.isEnabled) {
                        Text("No clock is shown in the menu bar. Open MoreClock again from Finder or Spotlight to get back to Settings.")
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 620)
    }

    private func expansionBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedClocks.contains(id) },
            set: { isExpanded in
                if isExpanded { expandedClocks.insert(id) } else { expandedClocks.remove(id) }
            }
        )
    }

    /// Reads and writes by id, not array index. A late write, such as a picker result
    /// arriving after a clock was removed, can't crash or edit the wrong clock.
    private func binding(for clock: ClockConfig) -> Binding<ClockConfig> {
        let id = clock.id
        return Binding(
            get: { store.clock(id: id) ?? clock },
            set: { newValue in store.update(id) { $0 = newValue } }
        )
    }
}

private struct ClockSection: View {
    @Binding var clock: ClockConfig
    @Binding var isExpanded: Bool
    let onDelete: () -> Void
    @State private var isPickingZone = false
    @State private var isConfirmingRemoval = false

    var body: some View {
        Section {
            if isExpanded {
                rows
            }
        } header: {
            // The whole header row toggles the section; the chevron sits at the trailing edge.
            Button {
                withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(clock.displayName)
                        .font(.headline)
                        .foregroundStyle(clock.isEnabled ? .primary : .secondary)
                        .lineLimit(1)
                    ClockPreview(clock: clock)
                    Spacer()
                    // Points up while collapsed and down while expanded. A vertical chevron
                    // looks the same in left-to-right and right-to-left layouts.
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .frame(width: 22, height: 22)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help(isExpanded ? Text("Collapse") : Text("Expand"))
            .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        }
    }

    @ViewBuilder
    private var rows: some View {
            // The placeholder shows the default, which is used whenever the field is empty.
            TextField("Name", text: $clock.name, prompt: Text(clock.defaultName))

            Toggle("Show in menu bar", isOn: $clock.isEnabled)

            LabeledContent("Time zone") {
                Button {
                    isPickingZone = true
                } label: {
                    HStack(spacing: 4) {
                        Text(zoneLabel)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                    }
                }
                .popover(isPresented: $isPickingZone, arrowEdge: .bottom) {
                    TimeZonePicker { selection, placeName in
                        clock.setTimeZone(selection, placeName: placeName)
                        isPickingZone = false
                    }
                }
            }

            TextField("Prefix", text: $clock.prefix, prompt: Text("e.g. 🇯🇵 or Tokyo"))

            Picker("Show date", selection: $clock.dateDisplay) {
                ForEach(DateDisplay.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }

            Toggle("Show seconds", isOn: $clock.showSeconds)

            Toggle("Bold", isOn: $clock.isBold)

            // Inside the expanded panel and behind a confirmation, so a stray click on a
            // header can't delete a clock.
            HStack {
                Spacer()
                Button("Remove Clock", systemImage: "trash", role: .destructive) {
                    isConfirmingRemoval = true
                }
            }
            .confirmationDialog(
                Text("Remove “\(clock.displayName)”?", comment: "%@ is the clock's name, e.g. Tokyo"),
                isPresented: $isConfirmingRemoval,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive, action: onDelete)
            } message: {
                Text("The clock is removed from the menu bar and from Settings.")
            }
    }

    private var zoneLabel: String {
        switch clock.selection {
        case .system:
            String(localized: "System (\(TimeZone.autoupdatingCurrent.identifier))",
                   comment: "Time zone button; %@ is the current system time zone identifier, e.g. Europe/Oslo")
        case .zone(let zone): zone.displayLabel()
        }
    }
}

/// A live preview of the menu bar title.
private struct ClockPreview: View {
    let clock: ClockConfig

    var body: some View {
        Group {
            if clock.showSeconds {
                // Anchored on a whole second so the preview ticks with the menu bar.
                TimelineView(.periodic(from: Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.down)), by: 1)) { context in
                    label(at: context.date)
                }
            } else {
                TimelineView(.everyMinute) { context in label(at: context.date) }
            }
        }
    }

    private func label(at date: Date) -> some View {
        // Mirrors the menu bar title, a step quieter than the clock's name next to it.
        Text(ClockFormatter.title(for: date, config: clock))
            .font(.system(.body, weight: clock.isBold ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

private extension DateDisplay {
    var title: LocalizedStringResource {
        switch self {
        case .none: "Off"
        case .weekday: "Weekday"
        case .date: "Date"
        case .weekdayAndDate: "Weekday and Date"
        }
    }
}
