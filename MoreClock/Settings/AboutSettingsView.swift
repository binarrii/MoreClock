import AppKit
import MoreClockKit
import SwiftUI

/// Settings › About: icon, name, version, build provenance and project links.
struct AboutSettingsView: View {
    private static let website = URL(string: "https://moreclock.skyviiew.com/")!
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

            VStack(spacing: 6) {
                linkRow(Text("Website:"), destination: Self.website)
                linkRow(Text("GitHub:"), destination: Self.repository)
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(width: 500, height: 352)
    }

    private func linkRow(_ label: Text, destination: URL) -> some View {
        HStack(spacing: 6) {
            label
            Link(destination: destination) {
                Text(verbatim: destination.absoluteString)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
