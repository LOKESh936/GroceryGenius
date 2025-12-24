import SwiftUI

struct AIQuickPromptChip: View {
    let text: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Haptic.light()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))

                Text(text)
                    .font(AppFont.body(14))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColor.accent)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
}
