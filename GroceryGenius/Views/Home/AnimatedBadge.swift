import SwiftUI

struct AnimatedBadge: View {

    let text: String
    @State private var pulse = false

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppColor.accent)
                    .scaleEffect(pulse ? 1.05 : 0.95)
            )
            .animation(
                .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                pulse = true
            }
    }
}
