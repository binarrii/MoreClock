import AppKit
import MoreClockKit
import SwiftUI

/// Settings › About: icon, name, version, build provenance and the project link.
struct AboutSettingsView: View {
    private static let repository = URL(string: "https://github.com/binarrii/MoreClock")!

    private let info = BuildInfo(infoDictionary: Bundle.main.infoDictionary ?? [:])
    private let name = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "MoreClock"

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 112, height: 112)
                .accessibilityHidden(true)

            Text(verbatim: name)
                .font(.title2.weight(.semibold))

            VStack(spacing: 6) {
                Text("Version: \(info.version) (\(info.build))")
                if let detail = info.detail() {
                    // Technical provenance, kept left-to-right in every language.
                    Text(verbatim: detail)
                        .monospacedDigit()
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            .foregroundStyle(.secondary)
            .textSelection(.enabled)

            HStack(spacing: 6) {
                Text("GitHub:")
                Link(destination: Self.repository) {
                    Text(verbatim: Self.repository.absoluteString)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(width: 500, height: 330)
    }
}
