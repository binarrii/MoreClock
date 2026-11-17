import MapKit
import MoreClockKit
import Observation

/// Search state for the time zone picker:
/// - offline time zone matches, recomputed once per query change
/// - MapKit city and country autocomplete, debounced
/// - resolving a picked place to its time zone
@MainActor
@Observable
final class LocationSearchService: NSObject, @MainActor MKLocalSearchCompleterDelegate {
    var query = "" {
        didSet { queryChanged() }
    }

    private(set) var localMatches: [TimeZone] = []
    private(set) var results: [MKLocalSearchCompletion] = []
    /// The query that produced `results`. Results are shown while typing but may be stale.
    private(set) var resultsQuery = ""
    private(set) var error: Error?
    private(set) var isSearching = false

    var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// True when `results` belong to the current query, so Return can safely pick the first one.
    var placeResultsAreCurrent: Bool { !isSearching && resultsQuery == trimmedQuery }

    @ObservationIgnored private let index = TimeZoneSearchIndex()
    @ObservationIgnored private let completer = MKLocalSearchCompleter()
    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.addressFilter = MKAddressFilter(including: [.locality, .administrativeArea, .country])
    }

    private func queryChanged() {
        let fragment = trimmedQuery
        localMatches = index.matches(for: fragment)
        debounceTask?.cancel()

        guard !fragment.isEmpty else {
            completer.cancel()
            completer.queryFragment = ""
            results = []
            resultsQuery = ""
            error = nil
            isSearching = false
            return
        }
        // MapKit sends no callback when the fragment is unchanged (a trailing space, or a
        // character typed and deleted within the debounce), so don't wait for one.
        if fragment == completer.queryFragment {
            isSearching = completer.isSearching
            return
        }
        isSearching = true
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            self.completer.queryFragment = fragment
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
        resultsQuery = completer.queryFragment
        error = nil
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        results = []
        resultsQuery = completer.queryFragment
        // "No results" also arrives as an error. Treat it as an empty list, not a failure.
        if (error as? MKError)?.code == .placemarkNotFound {
            self.error = nil
        } else {
            self.error = error
        }
        isSearching = false
    }

    func timeZone(for completion: MKLocalSearchCompletion) async throws -> TimeZone {
        let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()
        for item in response.mapItems {
            let address = item.addressRepresentations
            let regionCode = address?.region?.identifier
            let placeName = [address?.cityName, item.name, completion.title]
                .compactMap { $0 }
                .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if let zone = PlaceTimeZoneResolver.resolve(
                reportedZone: item.timeZone, regionCode: regionCode, placeName: placeName
            ) {
                return zone
            }
        }
        throw NoTimeZoneError()
    }
}

struct NoTimeZoneError: LocalizedError {
    var errorDescription: String? {
        String(localized: "Maps didn’t return a time zone for that place. Try a nearby city instead.")
    }
}
