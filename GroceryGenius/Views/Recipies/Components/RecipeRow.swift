import SwiftUI

struct RecipeRow: View {

    let recipe: Recipe

    private var subtitle: String {
        let tagText = recipe.tags.map(\.title)

        if !tagText.isEmpty {
            return tagText.prefix(3).joined(separator: " • ")
        }

        if !recipe.notes.isEmpty {
            return "Notes"
        }

        return "Saved recipe"
    }

    var body: some View {
        GGCard {
            HStack(spacing: 12) {

                Circle()
                    .fill(AppColor.chromeSurface)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(AppFont.subtitle(16))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 12)
        }
    }
}
