import SwiftUI

struct SettingsRow: View {

    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var titleColor: Color = AppColor.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(titleColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.subtitle(15))
                        .foregroundStyle(titleColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Spacer()

                if let trailingText {
                    Text(trailingText)
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}
