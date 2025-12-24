import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    @State private var appear = false

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.subtitle(17))
                .foregroundStyle(AppColor.textPrimary)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 6)

            if let subtitle {
                Text(subtitle)
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
                    .opacity(appear ? 0.9 : 0)
                    .offset(y: appear ? 0 : 6)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                appear = true
            }
        }
    }
}
