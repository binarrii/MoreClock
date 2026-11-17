import MapKit
import MoreClockKit
import SwiftUI

/// Search by city, country, time zone name, identifier or offset ("UTC+5:30").
/// Matching time zones come from Foundation and work offline. Places come from MapKit.
struct TimeZonePicker: View {
    /// The selection, plus the picked place's name when it came from Maps search (used as the clock's default name).
    let onPick: (TimeZoneSelection, _ placeName: String?) -> Void

    @State private var search = LocationSearchService()
    @State private var pickError: Error?
    @State private var resolving: MKLocalSearchCompletion?
    @State private var resolveTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $search.query, prompt: Text("City, country, time zone or UTC+5:30"))
                .textFieldStyle(.roundedBorder)
                // The popover inherits trailing alignment from its Settings form row.
                // Keep this search box left-aligned without changing the rest of the picker.
                .environment(\.layoutDirection, .leftToRight)
                .multilineTextAlignment(.leading)
                .focused($isSearchFocused)
                .onSubmit(pickFirst)
                .padding(10)

            Divider()

            List {
                if !search.localMatches.isEmpty {
                    Section("Time Zones") {
                        ForEach(search.localMatches, id: \.identifier) { zone in
                            Button { choose(.zone(zone)) } label: { ZoneRow(zone: zone) }
                        }
                    }
                }
                if !search.results.isEmpty {
                    Section("Places") {
                        ForEach(search.results, id: \.self) { completion in
                            Button { pick(completion) } label: {
                                PlaceRow(completion: completion, isResolving: resolving == completion)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .listStyle(.inset)
            .overlay { emptyState }

            Divider()

            HStack {
                Button("System Time Zone") { choose(.system) }
                Button("UTC") { choose(.zone(.gmt)) }
                Spacer()
                if search.isSearching || resolving != nil {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(10)
        }
        .frame(width: 380, height: 440)
        .onAppear { isSearchFocused = true }
        .onDisappear { cancelLookup() } // a late place lookup must not apply after the picker closes
        .alert(
            "Couldn’t Use That Place",
            isPresented: Binding(get: { pickError != nil }, set: { if !$0 { pickError = nil } })
        ) {
            Button("OK") {}
        } message: {
            Text(pickError?.localizedDescription ?? "")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let hasResults = !search.localMatches.isEmpty || !search.results.isEmpty
        if search.trimmedQuery.isEmpty {
            ContentUnavailableView(
                "Find a Time Zone",
                systemImage: "globe",
                description: Text("Type a city such as “Tokyo”, a zone such as “Pacific Time”, or an offset such as “UTC+5:30”.")
            )
        } else if !hasResults, let error = search.error {
            ContentUnavailableView(
                "Place Search Unavailable",
                systemImage: "exclamationmark.magnifyingglass",
                description: Text(error.localizedDescription)
            )
        } else if !hasResults, !search.isSearching {
            ContentUnavailableView.search(text: search.trimmedQuery)
        }
    }

    private func choose(_ selection: TimeZoneSelection) {
        cancelLookup()
        onPick(selection, nil)
    }

    private func pickFirst() {
        if let zone = search.localMatches.first {
            choose(.zone(zone))
        } else if search.placeResultsAreCurrent, let place = search.results.first {
            pick(place) // never a stale result from the previous query
        }
    }

    /// A failed lookup shows an error. It never quietly falls back to the system time zone.
    private func pick(_ completion: MKLocalSearchCompletion) {
        cancelLookup()
        resolving = completion
        resolveTask = Task {
            do {
                let zone = try await search.timeZone(for: completion)
                guard !Task.isCancelled else { return }
                resolving = nil
                onPick(.zone(zone), completion.title)
            } catch {
                guard !Task.isCancelled else { return }
                resolving = nil
                pickError = error
            }
        }
    }

    private func cancelLookup() {
        resolveTask?.cancel()
        resolveTask = nil
        resolving = nil
    }
}

private struct ZoneRow: View {
    let zone: TimeZone

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(zone.isFixedOffset ? zone.offsetLabel() : zone.identifier.replacingOccurrences(of: "_", with: " "))
                if !zone.isFixedOffset, let name = zone.localizedName(for: .generic, locale: .autoupdatingCurrent) {
                    Text(name).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !zone.isFixedOffset {
                Text(zone.offsetLabel()).monospacedDigit().foregroundStyle(.secondary)
            }
        }
        .contentShape(.rect)
    }
}

private struct PlaceRow: View {
    let completion: MKLocalSearchCompletion
    let isResolving: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isResolving { ProgressView().controlSize(.small) }
        }
        .contentShape(.rect)
    }
}
