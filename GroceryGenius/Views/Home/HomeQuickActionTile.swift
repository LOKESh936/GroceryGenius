import SwiftUI

struct HomeQuickActionTile: View {

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var badge: String? = nil
    var isDisabled: Bool = false

    @State private var pressed = false

    var body: some View {
        GGCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(color)
                    }

                    Spacer()

                    if let badge {
                        AnimatedBadge(text: badge)
                    }
                }

                Text(title)
                    .font(AppFont.subtitle(16))
                    .foregroundStyle(
                        isDisabled ? AppColor.textSecondary : AppColor.textPrimary
                    )

                Text(subtitle)
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .opacity(isDisabled ? 0.55 : 1)
        }
        .scaleEffect(pressed ? 0.96 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: pressed)
        .allowsHitTesting(!isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled {
                        pressed = true
                        Haptic.light()
                    }
                }
                .onEnded { _ in
                    pressed = false
                }
        )
    }
}
