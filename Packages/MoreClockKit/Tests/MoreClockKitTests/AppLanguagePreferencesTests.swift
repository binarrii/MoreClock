import Foundation
import Testing
@testable import MoreClockKit

@Suite("Native app language preference")
@MainActor
struct AppLanguagePreferencesTests {
    private let supported = ["en", "zh-Hans", "zh-Hant", "fr", "de", "pt-BR", "ar", "fa"]

    private func withPreferences(_ body: (UserDefaults, String, AppLanguagePreferences) throws -> Void) throws {
        let domain = "MoreClockLanguageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = AppLanguagePreferences(defaults: defaults, domainName: domain, supportedLanguages: supported)
        try body(defaults, domain, model)
    }

    @Test func inheritedLanguagesAreNotAnApplicationOverride() throws {
        try withPreferences { defaults, domain, model in
            defaults.register(defaults: ["AppleLanguages": ["fr", "en"]])
            #expect(defaults.stringArray(forKey: "AppleLanguages") != nil)
            model.refresh()
            #expect(model.selectedLanguage == nil)
            #expect(defaults.persistentDomain(forName: domain)?["AppleLanguages"] == nil)
        }
    }

    @Test func selectionWritesTheNativeKeyOnly() throws {
        try withPreferences { defaults, domain, model in
            let clocks = Data("saved clock configuration".utf8)
            defaults.set(clocks, forKey: "clocks")
            #expect(model.select("fa"))
            #expect(model.selectedLanguage == "fa")
            #expect(model.effectiveLanguage == "fa")
            let saved = defaults.persistentDomain(forName: domain)
            #expect(saved?["AppleLanguages"] as? [String] == ["fa"])
            #expect(defaults.data(forKey: "clocks") == clocks)
            #expect(saved?.keys.sorted() == ["AppleLanguages", "clocks"])
        }
    }

    @Test func systemDefaultRemovesTheOverrideRatherThanCopyingGlobalLanguages() throws {
        try withPreferences { defaults, domain, model in
            defaults.set("preserve me", forKey: "otherSetting")
            defaults.set(["fr"], forKey: "AppleLanguages")
            model.refresh()
            #expect(model.selectedLanguage == "fr")
            #expect(model.select(nil))
            #expect(model.selectedLanguage == nil)
            #expect(defaults.persistentDomain(forName: domain)?["AppleLanguages"] == nil)
            #expect(defaults.string(forKey: "otherSetting") == "preserve me")
        }
    }

    @Test(arguments: [("en-US", "en"), ("zh-Hans-CN", "zh-Hans"), ("zh-Hant-HK", "zh-Hant"), ("pt-BR", "pt-BR")])
    func systemWrittenRegionalOverridesUseTheMatchingSupportedLanguage(_ saved: String, _ expected: String) throws {
        try withPreferences { defaults, _, model in
            defaults.set([saved], forKey: "AppleLanguages")
            model.refresh()
            #expect(model.selectedLanguage == expected)
        }
    }

    @Test func externalSystemSettingsChangesAreReadOnRefresh() throws {
        try withPreferences { defaults, _, model in
            #expect(model.select("fr"))
            defaults.set(["ar"], forKey: "AppleLanguages") // The same app-domain write used by macOS.
            model.refresh()
            #expect(model.selectedLanguage == "ar")
            defaults.removeObject(forKey: "AppleLanguages")
            model.refresh()
            #expect(model.selectedLanguage == nil)
        }
    }

    @Test func unchangedAndUnsupportedSelectionsLeaveThePreferenceAlone() throws {
        try withPreferences { defaults, _, model in
            #expect(model.select("fr"))
            #expect(!model.select("fr"))
            #expect(!model.select("not-a-supported-language"))
            #expect(defaults.stringArray(forKey: "AppleLanguages") == ["fr"])
        }
    }

    @Test func emptyLanguageArrayMeansSystemDefault() throws {
        try withPreferences { defaults, _, model in
            defaults.set([String](), forKey: "AppleLanguages")
            model.refresh()
            #expect(model.selectedLanguage == nil)
        }
    }
}
