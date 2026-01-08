import SwiftUI

struct AIMessageBubbleView: View {
    let message: AIMsg
    var isStreaming: Bool = false

    let onCopy: () -> Void
    let onSpeak: () -> Void
    let onAddItems: () -> Void

    @State private var appear = false

    private var isUser: Bool { message.isUser }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {

            if !isUser {
                avatar
            } else {
                Spacer(minLength: 32)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {

                if !isUser {
                    Text("GroceryGenius AI")
                        .font(AppFont.caption(11))
                        .foregroundStyle(AppColor.textSecondary.opacity(0.8))
                        .padding(.leading, 4)
                }

                AIMarkdownMessageView(
                    text: message.text,
                    isUser: isUser
                )
                .padding(12)
                .background(bubbleBackground)     // ✅ FIXED HERE
                .overlay(bubbleStroke)
                .shadow(
                    color: .black.opacity(isUser ? 0.14 : 0.08),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                .contextMenu {
                    Button("Copy") { onCopy() }
                    if !isUser { Button("Speak") { onSpeak() } }
                    if !isUser { Button("Add items to grocery list") { onAddItems() } }
                }
            }
            .frame(maxWidth: 520, alignment: isUser ? .trailing : .leading)
            .scaleEffect(appear ? 1.0 : 0.98)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: appear)
            .onAppear { appear = true }

            if isUser {
                avatar.opacity(0) // alignment placeholder
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    isUser
                    ? AppColor.accent.opacity(0.2)
                    : AppColor.primary.opacity(0.18)
                )
                .frame(width: 30, height: 30)

            Image(systemName: isUser ? "person.fill" : "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isUser ? AppColor.accent : AppColor.primary)
        }
        .padding(.bottom, 2)
    }

    // MARK: - Bubble Background (✅ PALETTE BLENDED)

    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                isUser
                ? AppColor.accent.opacity(0.85)
                : AppColor.cardBackground.opacity(0.70) // ✅ WAS WHITE, NOW BLENDED
            )
            .overlay(
                // streaming border (unchanged)
                isStreaming && !isUser
                ? RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        AppColor.primary.opacity(0.45),
                        lineWidth: 1
                    )
                : nil
            )
    }

    // MARK: - Stroke

    private var bubbleStroke: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                isUser
                ? Color.clear
                : Color.white.opacity(0.25),
                lineWidth: 0.6
            )
    }
}
