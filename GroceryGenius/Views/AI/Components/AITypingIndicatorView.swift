import SwiftUI

struct AITypingIndicatorView: View {

    @State private var scale: CGFloat = 0.8

    var body: some View {
        HStack(spacing: 6) {
            dot(delay: 0)
            dot(delay: 0.15)
            dot(delay: 0.3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                scale = 1.2
            }
        }
    }

    private func dot(delay: Double) -> some View {
        Circle()
            .fill(AppColor.primary)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .animation(
                .easeInOut(duration: 0.8)
                    .repeatForever()
                    .delay(delay),
                value: scale
            )
    }
}
