import SwiftUI

struct MarkdownText: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .full)
        ) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}
