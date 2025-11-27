import SwiftUI

struct TypingBubbleView: View {
    @State private var animate = false

    var body: some View {
        HStack {
            // AI side (left)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(animate ? 0.3 : 1)

                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(animate ? 0.6 : 1)

                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(animate ? 1 : 0.3)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColor.primary)   // same green as AI bubble
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
            ) {
                animate.toggle()
            }
        }
    }
}
