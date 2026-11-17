import AppKit
import MoreClockKit
import SwiftUI

/// The same per-app language override used by macOS. Bundle localization and layout
/// direction are recreated on relaunch; there is no separate in-app translation override.
struct LanguageSetting: View {
    @State private var preferences: AppLanguagePreferences
    @State private var showsRelaunchPrompt = false
    @State private var isRelaunching = false
    @State private var relaunchError: String?
    private let runningLanguage: String

    init() {
        let bundle = Bundle.main
        let development = bundle.developmentLocalization ?? "en"
        let supported = [development] + bundle.localizations
            .filter { $0 != "Base" && $0 != development }.sorted()
        _preferences = State(initialValue: AppLanguagePreferences(
            domainName: bundle.bundleIdentifier ?? "com.skyviiew.MoreClock",
            supportedLanguages: supported
        ))
        runningLanguage = bundle.preferredLocalizations.first ?? development
    }

    private var requiresRelaunch: Bool {
        preferences.effectiveLanguage != runningLanguage
    }

    var body: some View {
        Section {
            Picker("Language", selection: Binding(
                get: { preferences.selectedLanguage ?? "" },
                set: { choice in
                    if preferences.select(choice.isEmpty ? nil : choice) {
                        showsRelaunchPrompt = requiresRelaunch
                    }
                }
            )) {
                Text("System Default").tag("")
                Divider()
                ForEach(languageChoices, id: \.code) { language in
                    Text(verbatim: language.name).tag(language.code)
                }
            }
            .disabled(isRelaunching)

            if requiresRelaunch {
                HStack {
                    Spacer()
                    Button("Relaunch Now", action: relaunch)
                        .disabled(isRelaunching)
                }
            }
        } footer: {
            Text("Language changes take effect after relaunch.")
        }
        .onAppear { preferences.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            preferences.refresh() // Pick up changes made through System Settings.
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: UserDefaults.standard)
            .receive(on: RunLoop.main)) { _ in
            preferences.refresh()
        }
        .alert("Relaunch MoreClock?", isPresented: $showsRelaunchPrompt) {
            Button("Relaunch Now", action: relaunch)
            Button("Later", role: .cancel) {}
        } message: {
            Text("Relaunch MoreClock to apply the new language.")
        }
        .alert("Couldn’t Relaunch MoreClock", isPresented: Binding(
            get: { relaunchError != nil },
            set: { if !$0 { relaunchError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(relaunchError ?? "")
        }
    }

    private var languageChoices: [(code: String, name: String)] {
        preferences.supportedLanguages.map { code in
            (code: code, name: (Locale(identifier: code).localizedString(forIdentifier: code) ?? code).localizedCapitalized)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func relaunch() {
        guard !isRelaunching else { return }
        isRelaunching = true
        Task { @MainActor in
            do {
                try await AppRelaunch.reopenSettings()
            } catch {
                isRelaunching = false
                relaunchError = error.localizedDescription
            }
        }
    }
}

/// Relaunch through Launch Services, so the new process receives macOS' language settings.
@MainActor
enum AppRelaunch {
    private static let settingsRequestKey = "reopenSettingsAfterLanguageChange"

    static func consumeSettingsRequest() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: settingsRequestKey) else { return false }
        defaults.removeObject(forKey: settingsRequestKey)
        defaults.synchronize()
        return true
    }

    static func reopenSettings() async throws {
        let defaults = UserDefaults.standard
        // Sandboxed callers cannot pass launch arguments. Use a one-shot preference instead.
        defaults.set(true, forKey: settingsRequestKey)
        defaults.synchronize()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.addsToRecentItems = false
        do {
            _ = try await NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration)
        } catch {
            defaults.removeObject(forKey: settingsRequestKey)
            defaults.synchronize()
            throw error // Keep the current process alive if launch fails.
        }
        NSApp.terminate(nil)
    }
}
