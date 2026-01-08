import SwiftUI

struct AIChatRowView: View {
    let conversation: AIConversation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.system(size: 16, weight: .semibold))

            Text(conversation.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
