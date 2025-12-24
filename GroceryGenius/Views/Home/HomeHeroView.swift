import SwiftUI

struct HomeHeroView: View {

    @State private var animate = false

    var body: some View {
        GGCard(cornerRadius: 28) {
            HStack(spacing: 18) {

                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome back 👋")
                        .font(AppFont.title(26))
                        .foregroundStyle(AppColor.primary)

                    Text("What would you like to do today?")
                        .font(AppFont.body(15))
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColor.primary,
                                    AppColor.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .scaleEffect(animate ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: true),
                            value: animate
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(animate ? 8 : -8))
                        .animation(
                            .easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: true),
                            value: animate
                        )
                }
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .onAppear {
            animate = true
        }
    }
}
