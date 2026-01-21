import SwiftUI

struct RecipeRow: View {
    let recipe: RecipeUIModel

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
                        .font(AppFont.subtitle(15))

                    Text(recipe.subtitle)
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)

                    Text(recipe.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFont.caption(11))
                        .foregroundStyle(AppColor.textSecondary.opacity(0.85))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary.opacity(0.7))
            }
        }
    }
}
