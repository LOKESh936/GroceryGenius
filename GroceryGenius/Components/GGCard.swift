import SwiftUI

struct GGCard<Content: View>: View {

    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let content: () -> Content
    var onTap: (() -> Void)?

    @State private var isPressed = false

    init(
        cornerRadius: CGFloat = 20,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onTap = onTap
        self.content = content
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColor.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .shadow(
                    color: .black.opacity(isPressed ? 0.12 : 0.18),
                    radius: isPressed ? 4 : 10,
                    x: 0,
                    y: isPressed ? 2 : 6
                )

            content()
                .padding(padding)   
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
        .gesture(
            onTap == nil ? nil :
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    Haptic.medium()
                    onTap?()
                }
        )
    }
}
