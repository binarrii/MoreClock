import Foundation
import Observation

/// Uses the native per-application language preference shared with macOS System Settings.
/// A nil selection means inheritance: the app-specific AppleLanguages key is absent.
@MainActor
@Observable
public final class AppLanguagePreferences {
    public let supportedLanguages: [String]
    public private(set) var selectedLanguage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let domainName: String
    private static let key = "AppleLanguages"

    public init(defaults: UserDefaults = .standard, domainName: String, supportedLanguages: [String]) {
        self.defaults = defaults
        self.domainName = domainName
        self.supportedLanguages = supportedLanguages
        refresh()
    }

    /// Read the application domain only. `stringArray(forKey:)` alone also returns the
    /// global language list and would incorrectly show a system default as an app override.
    public func refresh() {
        let languages = defaults.persistentDomain(forName: domainName)?[Self.key] as? [String]
        guard let languages, !languages.isEmpty else {
            selectedLanguage = nil
            return
        }
        selectedLanguage = preferredLanguage(for: languages)
    }

    /// The localization a fresh launch will choose. When there is no app override,
    /// UserDefaults supplies the inherited system language preference.
    public var effectiveLanguage: String? {
        let preferences = selectedLanguage.map { [$0] } ?? defaults.stringArray(forKey: Self.key) ?? []
        return preferredLanguage(for: preferences)
    }

    /// Returns whether the app override changed. Never changes global preferences.
    @discardableResult
    public func select(_ language: String?) -> Bool {
        if let language, !supportedLanguages.contains(language) { return false }
        refresh()
        guard selectedLanguage != language else { return false }
        if let language {
            defaults.set([language], forKey: Self.key)
        } else {
            defaults.removeObject(forKey: Self.key)
        }
        // Language changes are rare and may immediately launch a replacement process.
        // Flush this preference before asking Launch Services to start that process.
        defaults.synchronize()
        refresh()
        return true
    }

    private func preferredLanguage(for preferences: [String]) -> String? {
        Bundle.preferredLocalizations(from: supportedLanguages, forPreferences: preferences).first
    }
}
