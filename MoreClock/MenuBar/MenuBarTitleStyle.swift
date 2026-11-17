import AppKit
import CoreText

/// Gives flag emoji their own size and baseline while keeping the native status-item label.
/// No foreground color is specified: AppKit still owns highlight and inactive-display colors.
enum MenuBarTitleStyle {
    static func title(_ title: String, prefix: String, font: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: title, attributes: [.font: font])
        let prefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefix.isEmpty, title.hasPrefix(prefix) else { return result }

        let text = String(title.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        let textBounds = inkBounds(text, font: font)
        let flagFont = NSFont.systemFont(ofSize: font.pointSize * 1.15)

        // Work in Character ranges, so country pairs and subdivision flag sequences stay intact.
        for index in prefix.indices {
            let character = prefix[index]
            guard isFlag(character) else { continue }
            let flagBounds = inkBounds(String(character), font: flagFont)
            var attributes: [NSAttributedString.Key: Any] = [.font: flagFont]
            if !textBounds.isEmpty, !textBounds.isNull, !flagBounds.isEmpty, !flagBounds.isNull {
                // Emoji and text fonts have different ascenders and internal padding. Align their
                // visible glyphs rather than their nominal line boxes.
                attributes[.baselineOffset] = textBounds.midY - flagBounds.midY
            }
            let range = NSRange(index..<prefix.index(after: index), in: prefix)
            result.addAttributes(attributes, range: range)
        }
        return result
    }

    private static func isFlag(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        if scalars.count == 2, scalars.allSatisfy({ (0x1F1E6...0x1F1FF).contains($0.value) }) {
            return true // Country flags, e.g. 🇭🇰.
        }
        // White/black flags, including pride and subdivision sequences.
        return scalars.first.map { $0.value == 0x1F3F3 || $0.value == 0x1F3F4 } ?? false
    }

    private static func inkBounds(_ text: String, font: NSFont) -> CGRect {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        return CTLineGetImageBounds(line, nil)
    }
}
