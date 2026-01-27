import SwiftUI

struct RecipeDetailView: View {

    let recipe: Recipe

    @EnvironmentObject private var vm: RecipesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ingredients: [RecipeIngredient] = []
    @State private var isLoading = true

    // Sheets / Alerts
    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(AppFont.title(22))
                        .foregroundStyle(AppColor.textPrimary)

                    if !recipe.notes.isEmpty {
                        Text(recipe.notes)
                            .font(AppFont.body(15))
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    // ✅ Last updated
                    Text("Last updated \(recipe.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.top, 2)
                }

                // MARK: - Tags
                if !recipe.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(recipe.tags) { tag in
                            Label(tag.title, systemImage: tag.systemImage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppColor.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(AppColor.chromeSurface)
                                )
                        }
                    }
                }

                Divider()

                // MARK: - Ingredients
                VStack(alignment: .leading, spacing: 12) {

                    HStack {
                        Text("Ingredients")
                            .font(AppFont.subtitle(16))
                            .foregroundStyle(AppColor.textPrimary)

                        Spacer()

                        Text("\(ingredients.count)")
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    if isLoading {
                        ProgressView()
                            .padding(.vertical, 12)

                    } else if ingredients.isEmpty {
                        Text("No ingredients yet.")
                            .font(AppFont.body(14))
                            .foregroundStyle(AppColor.textSecondary)

                    } else {
                        VStack(spacing: 8) {
                            ForEach(ingredients) { ing in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ing.name)
                                            .font(AppFont.body(15))
                                            .foregroundStyle(AppColor.textPrimary)

                                        if !ing.quantity.isEmpty {
                                            Text(ing.quantity)
                                                .font(AppFont.caption(13))
                                                .foregroundStyle(AppColor.textSecondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                // ✅ Swipe to edit
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        showEditor = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppColor.primary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }

        // ✅ Pull to refresh
        .refreshable {
            await reloadIngredients()
        }

        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Toolbar
        .toolbar {

            // Edit
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditor = true
                }
            }

            // Delete
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }

        // MARK: - Edit Sheet
        .sheet(isPresented: $showEditor) {
            RecipeEditorSheetView(mode: .edit(recipe))
                .environmentObject(vm)
        }

        // MARK: - Delete confirmation
        .alert("Delete Recipe?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await vm.deleteRecipe(recipe)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }

        .onAppear {
            loadIngredients()
        }
    }

    // MARK: - Load ingredients
    private func loadIngredients() {
        isLoading = true
        Task {
            let items = await vm.loadIngredients(recipeId: recipe.id)
            await MainActor.run {
                ingredients = items
                isLoading = false
            }
        }
    }

    private func reloadIngredients() async {
        let items = await vm.loadIngredients(recipeId: recipe.id)
        await MainActor.run {
            ingredients = items
        }
    }
}
