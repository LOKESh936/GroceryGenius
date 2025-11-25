import SwiftUI

struct TypingBubbleView: View {
    var body: some View {
        HStack {
            // AI side (left)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 6, height: 6)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Color(red: 0.27, green: 0.46, blue: 0.23)
                )
                .clipShape(ChatBubbleShape(isUser: false))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: UUID())
    }
}
