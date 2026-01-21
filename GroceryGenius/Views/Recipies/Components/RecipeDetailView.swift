import SwiftUI


struct RecipeDetailView: View {
    let recipe: RecipeUIModel

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GGCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(AppFont.title(22))

                            Text(recipe.subtitle)
                                .font(AppFont.body(14))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}
