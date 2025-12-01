import SwiftUI

struct MarkdownText: View {
    let text: String

    // Helper to produce an AttributedString from markdown with full syntax
    private var attributed: AttributedString? {
        var result: AttributedString?
        do {
            var parsingOptions = AttributedString.MarkdownParsingOptions()
            parsingOptions.interpretedSyntax = .full
            result = try AttributedString(markdown: text, options: parsingOptions)
        } catch {
            result = nil
        }
        return result
    }

    // Cleans AI-generated text and applies paragraph styling
    private func cleanAIText(_ text: String) -> AttributedString {
        var t = text
        t = t.replacingOccurrences(of: "&nbsp;", with: " ")
        t = t.replacingOccurrences(of: "  ", with: " ")
        t = t.replacingOccurrences(of: "\t", with: " ")
        return AttributedString(t)
    }

    var body: some View {
        Group {
            if let attributed {
                // Render attributed markdown text with standard SwiftUI modifiers
                Text(attributed)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .lineSpacing(4)
            } else {
                Text(cleanAIText(text))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 2)
        // Constrain line length for aesthetics without private environment keys
        .frame(maxWidth: 720, alignment: .leading)
    }
}

