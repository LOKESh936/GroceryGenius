import SwiftUI

struct MarkdownText: View {
    let text: String

    // Try to produce an AttributedString from markdown with full syntax.
    // If parsing fails, attempt to normalize common AI artifacts into valid markdown.
    private var attributed: AttributedString? {
        // First try: as-is
        if let parsed = tryParseMarkdown(text) {
            return parsed
        }
        // Second try: normalized markdown from AI text
        let normalized = normalizedAIText(text)
        let promoted = promoteHeadings(in: normalized)
        if let parsed = tryParseMarkdown(promoted) {
            return parsed
        }
        return nil
    }

    // Fallback plain text preserving line breaks
    private var fallbackPlain: String {
        promoteHeadings(in: normalizedAIText(text))
    }

    // MARK: - Parsing helpers

    private func tryParseMarkdown(_ source: String) -> AttributedString? {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .full
            return try AttributedString(markdown: source, options: options)
        } catch {
            return nil
        }
    }

    // Normalize AI text while preserving structure cues like bullets and line breaks.
    private func normalizedAIText(_ raw: String) -> String {
        var s = raw
        // Decode common HTML-ish artifacts and normalize whitespace
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "&nbsp;", with: " ")
        s = s.replacingOccurrences(of: "\t", with: " ")
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space
        // Normalize fancy dashes to a plain dash
        s = s.replacingOccurrences(of: "\u{2014}", with: "-") // em dash
        s = s.replacingOccurrences(of: "\u{2013}", with: "-") // en dash

        // Heuristic 1: ensure sentence breaks become newlines when AI omitted them.
        // Add a newline after ".", "?", or "!" when followed by an uppercase letter and no newline.
        let punctuation: [Character] = [".", "?", "!"]
        var rebuilt: String = ""
        let chars = Array(s)
        for i in chars.indices {
            let c = chars[i]
            rebuilt.append(c)
            if punctuation.contains(c) {
                let j = i + 1
                if j < chars.count {
                    let next = chars[j]
                    if next == "\"" { // skip quote immediately after punctuation
                        if j + 1 < chars.count, chars[j + 1].isLetter, chars[j + 1].isUppercase {
                            rebuilt.append("\n")
                        }
                    } else if next.isLetter, next.isUppercase {
                        rebuilt.append("\n")
                    }
                }
            }
        }
        s = rebuilt

        // Heuristic 2: Insert breaks before common section cues
        let sectionCues = [
            "Day ", "Breakfast", "Lunch", "Dinner", "Snacks", "Snack", "Ingredients", "Instructions", "Summary", "Key Points", "Key Takeaways"
        ]
        for cue in sectionCues {
            // Insert a newline before the cue if it's mid-line without one
            s = s.replacingOccurrences(of: " " + cue, with: "\n\n" + cue)
        }

        // Heuristic 2b: Split concatenated tokens like "Day 1Breakfast" or "LunchGrilled"
        do {
            let tokens = ["Breakfast", "Lunch", "Dinner", "Snacks", "Snack"]
            let scalarsView = s.unicodeScalars
            var result = ""
            var i = scalarsView.startIndex
            while i < scalarsView.endIndex {
                let currentScalar = scalarsView[i]
                result.unicodeScalars.append(currentScalar)

                // Lookahead index (i + 1)
                let nextIndex = scalarsView.index(after: i)
                if nextIndex < scalarsView.endIndex {
                    let nextScalar = scalarsView[nextIndex]

                    // If current is letter or number and next is uppercase letter, check for known token
                    let currentChar = Character(currentScalar)
                    let nextChar = Character(nextScalar)
                    if currentChar.isLetter || currentChar.isNumber {
                        if nextChar.isLetter, nextChar.isUppercase {
                            let remainderScalars = scalarsView[nextIndex..<scalarsView.endIndex]
                            let remainder = String(String.UnicodeScalarView(remainderScalars))
                            if let token = tokens.first(where: { remainder.hasPrefix($0) }) {
                                _ = token // silence unused variable; presence indicates a match
                                result.append("\n")
                            }
                        }
                    }
                }

                i = scalarsView.index(after: i)
            }
            s = result
            // Additionally, split specifically after patterns like "Day <digits>" when merged
            let dayMergedPatterns = ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"]
            for p in dayMergedPatterns {
                s = s.replacingOccurrences(of: p + "Breakfast", with: p + "\nBreakfast")
                s = s.replacingOccurrences(of: p + "Lunch", with: p + "\nLunch")
                s = s.replacingOccurrences(of: p + "Dinner", with: p + "\nDinner")
                s = s.replacingOccurrences(of: p + "Snacks", with: p + "\nSnacks")
            }
        }

        // Heuristic 3: If a line ends with a colon, treat next part as a list/paragraph start
        s = s.replacingOccurrences(of: ": ", with: ":\n")

        // Collapse runs of spaces but keep double spaces for markdown line breaks
        while s.contains("   ") { s = s.replacingOccurrences(of: "   ", with: "  ") }

        // Ensure list markers are markdown-friendly at line starts
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var out: [String] = []
        var previousWasList = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                previousWasList = false
                out.append("")
                continue
            }

            // Normalize bullet markers
            if trimmed.hasPrefix("• ") || trimmed.hasPrefix("•") {
                previousWasList = true
                out.append("- " + trimmed.drop(while: { $0 == "•" || $0 == " " }))
                continue
            }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                previousWasList = true
                out.append(trimmed)
                continue
            }
            // Numbered list like 1) or 1. or (1)
            if let match = trimmed.prefix(while: { $0.isNumber }).nonEmpty, trimmed.dropFirst(match.count).trimmingCharacters(in: .whitespaces).first.map({ $0 == "." || $0 == ")" }) == true {
                previousWasList = true
                let rest = trimmed.drop(while: { $0.isNumber || $0 == "." || $0 == ")" || $0 == " " })
                out.append("1. " + rest)
                continue
            }

            // Convert patterns like "BreakfastSomething" into a heading + content
            let headingTokens = ["Breakfast", "Lunch", "Dinner", "Snacks", "Snack", "Ingredients", "Instructions"]
            var handled = false
            for token in headingTokens {
                if trimmed.hasPrefix(token) && trimmed.count > token.count {
                    // Insert a line break after the token if missing
                    let idx = trimmed.index(trimmed.startIndex, offsetBy: token.count)
                    if trimmed[idx] != ":" {
                        out.append("## " + token)
                        out.append(String(trimmed[idx...]).trimmingCharacters(in: .whitespaces))
                        handled = true
                        break
                    }
                }
            }
            if handled { continue }

            // Keep code fences intact if present
            if trimmed.hasPrefix("```") {
                previousWasList = false
                out.append(trimmed)
                continue
            }

            // If we were in a list and the next line is indented, keep indentation
            if previousWasList && line.hasPrefix("  ") {
                out.append(line)
                continue
            }

            previousWasList = false
            out.append(line)
        }

        // Ensure a blank line between blocks to help markdown render paragraphs/lists
        var normalized = out.joined(separator: "\n")
        while normalized.contains("\n\n\n") { normalized = normalized.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return normalized
    }

    // Promote plain title-like lines into markdown headings when not already marked.
    private func promoteHeadings(in text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var out: [String] = []
        for i in lines.indices {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                out.append(line)
                continue
            }
            // Skip if already a heading or list or code fence
            if trimmed.hasPrefix("#") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") || trimmed.hasPrefix("1.") || trimmed.hasPrefix("```") {
                out.append(line)
                continue
            }
            // Heuristic: short lines (<= 80 chars) followed by a blank line become headings
            let nextIsBlank = (i + 1 < lines.count) ? lines[i + 1].trimmingCharacters(in: .whitespaces).isEmpty : true
            if trimmed.count <= 80 && nextIsBlank {
                out.append("## " + trimmed)
            } else {
                out.append(line)
            }
        }
        return out.joined(separator: "\n")
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
                // Fallback preserves newlines and spacing
                Text(verbatim: fallbackPlain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 2)
        // Constrain line length for aesthetics without private environment keys
        .frame(maxWidth: 720, alignment: .leading)
    }
}

private extension Substring {
    var nonEmpty: Substring? { isEmpty ? nil : self }
}
