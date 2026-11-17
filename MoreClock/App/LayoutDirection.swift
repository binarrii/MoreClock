import AppKit
import SwiftUI

/// The layout direction of the localization the app is actually running in.
///
/// AppKit doesn't always mirror an app whose language differs from the system's, for
/// example with a per-app language or `-AppleLanguages`. So the direction is derived from
/// `Bundle.main.preferredLocalizations` and applied explicitly to the SwiftUI views and menus.
enum AppLayout {
    static let isRightToLeft: Bool = {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale.Language(identifier: language).characterDirection == .rightToLeft
    }()

    static var swiftUI: SwiftUI.LayoutDirection { isRightToLeft ? .rightToLeft : .leftToRight }
    static var appKit: NSUserInterfaceLayoutDirection { isRightToLeft ? .rightToLeft : .leftToRight }
}
