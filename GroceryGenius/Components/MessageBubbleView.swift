import SwiftUI

struct MessageBubbleView: View {
    let message: AIMsg
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: .leading, spacing: 4) {
                MarkdownText(text: message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.isUser ? .white : .white)
            }
            .padding(12)
            .background(
                message.isUser
                ? Color.orange
                : Color(red: 0.27, green: 0.46, blue: 0.23) // WhatsApp-ish green
            )
            .clipShape(ChatBubbleShape(isUser: message.isUser))
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
            
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Bubble shape

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = RoundedRectangle(cornerRadius: 20).path(in: rect)
        
        // Optional: tweak one corner like WhatsApp
        let tailSize: CGFloat = 6
        
        if isUser {
            // cut bottom-right a bit
            path.addRect(
                CGRect(
                    x: rect.maxX - tailSize,
                    y: rect.maxY - tailSize,
                    width: tailSize,
                    height: tailSize
                )
            )
        } else {
            // cut bottom-left
            path.addRect(
                CGRect(
                    x: rect.minX,
                    y: rect.maxY - tailSize,
                    width: tailSize,
                    height: tailSize
                )
            )
        }
        return path
    }
}
