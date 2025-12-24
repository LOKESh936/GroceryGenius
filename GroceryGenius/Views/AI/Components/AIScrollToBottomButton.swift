import SwiftUI

struct AIScrollToBottomButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.light()
            action()
        } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(12)
                .background(AppColor.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scroll to bottom")
    }
}
