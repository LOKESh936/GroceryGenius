import SwiftUI

struct MessageBubbleView: View {
    let msg: AIMsg
    
    var body: some View {
        HStack {
            if msg.isUser { Spacer() }
            
            Text(msg.text)
                .padding(12)
                .background(msg.isUser ? AppColor.accent : AppColor.primary)
                .foregroundColor(.white)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: msg.isUser ? .trailing : .leading)
            
            if !msg.isUser { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
