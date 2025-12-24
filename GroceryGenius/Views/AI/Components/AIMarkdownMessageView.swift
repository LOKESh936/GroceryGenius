import SwiftUI

struct AIMarkdownMessageView: View {

    let text: String
    let isUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parse(text)) { block in
                switch block {

                case .heading(let title):
                    Text(title)
                        .font(AppFont.subtitle(18))
                        .foregroundStyle(AppColor.primary)

                case .subheading(let title):
                    Text(title)
                        .font(AppFont.subtitle(16))
                        .foregroundStyle(AppColor.textPrimary)

                case .ingredient(let name, let quantity):
                    AIIngredientRowView(
                        name: name,
                        quantity: quantity
                    )

                case .note(let text):
                    Text(text)
                        .font(AppFont.caption(13))
                        .foregroundStyle(AppColor.textSecondary)
                        .italic()

                case .paragraph(let text):
                    Text(text)
                        .font(AppFont.body(14))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .textSelection(.enabled)
    }
}

// MARK: - Parsing Model

private enum AIBlock: Identifiable {

    case heading(String)
    case subheading(String)
    case ingredient(name: String, quantity: String)
    case note(String)
    case paragraph(String)

    var id: UUID { UUID() }
}

// MARK: - Parser

private func parse(_ raw: String) -> [AIBlock] {

    let lines = raw
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    var blocks: [AIBlock] = []

    for line in lines {

        // ### Day X
        if line.hasPrefix("###") {
            blocks.append(
                .heading(
                    line.replacingOccurrences(of: "###", with: "")
                        .trimmingCharacters(in: .whitespaces)
                )
            )
            continue
        }

        // # Dinner
        if line.hasPrefix("#") {
            blocks.append(
                .subheading(
                    line.replacingOccurrences(of: "#", with: "")
                        .trimmingCharacters(in: .whitespaces)
                )
            )
            continue
        }

        // - **Title**
        if line.hasPrefix("- **") && line.hasSuffix("**") {
            blocks.append(
                .subheading(
                    line.replacingOccurrences(of: "- **", with: "")
                        .replacingOccurrences(of: "**", with: "")
                )
            )
            continue
        }

        // Ingredient bullet
        if line.hasPrefix("•") || line.hasPrefix("-") {

            let cleaned = line
                .replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "-", with: "")
                .trimmingCharacters(in: .whitespaces)

            let parts = cleaned.split(separator: ",")

            let name = parts.first.map { String($0) } ?? cleaned
            let quantity = parts.dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces)

            blocks.append(.ingredient(name: name, quantity: quantity))
            continue
        }

        // *note*
        if line.hasPrefix("(") && line.hasSuffix(")") {
            blocks.append(
                .note(
                    line.replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                )
            )
            continue
        }

        // Paragraph
        blocks.append(.paragraph(line))
    }

    return blocks
}
