import SwiftUI

struct RecipeRow: View {

    let recipe: Recipe

    var body: some View {
        GGCard {
            HStack(spacing: 12) {

                // Icon
                Circle()
                    .fill(AppColor.chromeSurface)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                    )

                VStack(alignment: .leading, spacing: 6) {

                    // Title
                    Text(recipe.title)
                        .font(AppFont.subtitle(16))
                        .foregroundStyle(AppColor.textPrimary)

                    // ✅ TAG CHIPS ROW
                    if !recipe.tags.isEmpty {
                        tagChips
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.textSecondary.opacity(0.6))
            }
        }
    }

    // MARK: - Chips
    private var tagChips: some View {
        HStack(spacing: 6) {
            ForEach(recipe.tags.prefix(3)) { tag in
                TagChipView(tag: tag)
            }
        }
    }
}
private struct TagChipView: View {

    let tag: RecipeTag

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.systemImage)
                .font(.system(size: 10, weight: .semibold))

            Text(tag.title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(AppColor.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(AppColor.chromeSurface)
        )
    }
}
