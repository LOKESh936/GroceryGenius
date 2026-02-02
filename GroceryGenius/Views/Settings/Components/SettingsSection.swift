import SwiftUI

struct SettingsSection<Content: View>: View {

    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(AppFont.caption(12))
                .foregroundStyle(AppColor.textSecondary)

            GGCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}
