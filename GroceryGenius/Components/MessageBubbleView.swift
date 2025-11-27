import SwiftUI

struct MessageBubbleView: View {
    let message: AIMsg

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
                        
            VStack(alignment: .leading, spacing: 6) {
                MarkdownText(text: message.text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isUser
                ? AppColor.accent           // orange for user
                : AppColor.primary          // green for AI
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.78,
                   alignment: .leading)

            if !message.isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
