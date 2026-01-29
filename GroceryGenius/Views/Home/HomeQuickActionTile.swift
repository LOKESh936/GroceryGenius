import SwiftUI

struct HomeQuickActionTile: View {

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var badge: String? = nil
    var isDisabled: Bool = false
    let onTap: () -> Void   // 👈 action injected

    @State private var pressed = false

    var body: some View {
        Button {
            guard !isDisabled else { return }
            onTap()                 // ✅ navigation fires here
        } label: {
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
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.96 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: pressed)
        .onLongPressGesture(
            minimumDuration: 0.01,
            pressing: { isPressing in
                guard !isDisabled else { return }
                pressed = isPressing
                if isPressing { Haptic.light() }
            },
            perform: {}
        )
    }
}
