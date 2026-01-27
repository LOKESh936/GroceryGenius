import SwiftUI

struct IngredientEditorView: View {

    @Binding var ingredients: [RecipeIngredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Ingredients")
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                Button {
                    Haptic.light()
                    ingredients.append(.init(name: "", quantity: ""))
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.primary)
                }
                .buttonStyle(.plain)
            }

            if ingredients.isEmpty {
                Text("No ingredients yet.")
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.vertical, 6)
            } else {
                ForEach($ingredients) { $ing in
                    GGCard(cornerRadius: 16, padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12)) {
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(AppColor.textSecondary.opacity(0.7))

                            VStack(spacing: 8) {
                                TextField("Ingredient", text: $ing.name)
                                    .font(AppFont.body(15))
                                    .textInputAutocapitalization(.words)

                                TextField("Quantity (e.g., 2 cups)", text: $ing.quantity)
                                    .font(AppFont.caption(13))
                                    .foregroundStyle(AppColor.textSecondary)
                            }

                            Spacer()

                            Button {
                                Haptic.light()
                                ingredients.removeAll { $0.id == ing.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Reorder hint (SwiftUI reorder is List-native; this keeps it clean in ScrollView)
                Text("Tip: keep the most important ingredients at the top.")
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, 2)
            }
        }
    }
}
