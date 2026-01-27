import SwiftUI

struct RecipeEditorSheetView: View {

    enum Mode {
        case create
        case edit(Recipe)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: RecipesViewModel

    let mode: Mode

    // MARK: - Form State
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var tags: Set<RecipeTag> = []
    @State private var ingredients: [RecipeIngredient] = []

    // MARK: - Conflict Detection
    @State private var recipeId: String?
    @State private var expectedRevision: Int = 0
    @State private var conflictRecipe: Recipe?
    @State private var showConflictAlert = false

    // MARK: - UI State
    @State private var isSaving = false
    @FocusState private var isTitleFocused: Bool
    
    @State private var saveErrorMessage: String? = nil


    // MARK: - Derived
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navTitle: String {
        switch mode {
        case .create: return "New Recipe"
        case .edit:   return "Edit Recipe"
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {

                        // MARK: - Main Card
                        GGCard {
                            VStack(alignment: .leading, spacing: 12) {

                                Text("Recipe title")
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(AppColor.textSecondary)

                                TextField("e.g., Chicken Rice Bowl", text: $title)
                                    .font(AppFont.body(16))
                                    .padding(12)
                                    .background(AppColor.cardElevated)
                                    .cornerRadius(12)
                                    .focused($isTitleFocused)

                                Divider().opacity(0.35)

                                Text("Notes")
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(AppColor.textSecondary)

                                TextEditor(text: $notes)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .frame(minHeight: 120)
                                    .padding(10)
                                    .background(AppColor.cardElevated)
                                    .cornerRadius(12)

                                Divider().opacity(0.35)

                                Text("Tags")
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(AppColor.textSecondary)

                                tagRow
                            }
                        }

                        // MARK: - Ingredients
                        GGCard {
                            IngredientEditorView(ingredients: $ingredients)
                        }

                        // MARK: - Save Button (FIXED)
                        Button {
                            Task {
                                await save()
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save")
                                .font(AppFont.subtitle(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(isValid ? AppColor.primary : AppColor.primary.opacity(0.4))
                                )
                        }
                        .disabled(!isValid || isSaving)
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }
            }
            .task { await bootstrap() }
            .alert("Conflict Detected", isPresented: $showConflictAlert) {
                Button("Reload Latest", role: .cancel) {
                    if let latest = conflictRecipe {
                        apply(recipe: latest)
                    }
                }
                Button("Overwrite Anyway", role: .destructive) {
                    Task { await forceOverwrite() }
                }
            } message: {
                Text("This recipe was updated on another device. Reload latest to avoid losing changes, or overwrite anyway.")
            }
            .alert("Save failed", isPresented: .constant(saveErrorMessage != nil)) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "Unknown error")
            }

        }
    }

    // MARK: - Bootstrap
    private func bootstrap() async {
        switch mode {
        case .create:
            recipeId = nil
            expectedRevision = 0
            title = ""
            notes = ""
            tags = []
            ingredients = []

        case .edit(let recipe):
            apply(recipe: recipe)
            ingredients = await vm.loadIngredients(recipeId: recipe.id)
        }
    }

    private func apply(recipe: Recipe) {
        recipeId = recipe.id
        expectedRevision = recipe.revision
        title = recipe.title
        notes = recipe.notes
        tags = Set(recipe.tags)
    }

    // MARK: - Tags UI
    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecipeTag.allCases) { tag in
                    let selected = tags.contains(tag)

                    Button {
                        Haptic.light()
                        if selected { tags.remove(tag) } else { tags.insert(tag) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tag.systemImage)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tag.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(selected ? Color.white : AppColor.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selected ? AppColor.primary : AppColor.chromeSurface.opacity(0.85))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Save (ASYNC SAFE)
    @MainActor
    private func save() async {
        guard isValid else { return }

        isSaving = true
        defer { isSaving = false }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanIngredients = ingredients
            .map {
                RecipeIngredient(
                    id: $0.id,
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    quantity: $0.quantity.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.name.isEmpty }

        do {
            switch mode {

            case .create:
                try await vm.createRecipe(
                    title: cleanTitle,
                    notes: notes,
                    tags: Array(tags),
                    ingredients: cleanIngredients
                )
                Haptic.medium()
                dismiss()

            case .edit:
                guard let id = recipeId else { return }

                let updated = Recipe(
                    id: id,
                    title: cleanTitle,
                    notes: notes,
                    tags: Array(tags),
                    createdAt: Date(), // merged server-side
                    updatedAt: Date(),
                    revision: expectedRevision
                )

                do {
                    try await vm.updateRecipe(
                        recipe: updated,
                        ingredients: cleanIngredients,
                        expectedRevision: expectedRevision
                    )
                    Haptic.medium()
                    dismiss()
                } catch let err as RecipesStore.ConflictError {
                    if case .conflict(let current) = err {
                        conflictRecipe = current
                        showConflictAlert = true
                    }
                }
            }
        } catch {
            print("❌ Save failed:", error)
            saveErrorMessage = String(describing: error)
        }
    }

    // MARK: - Force Overwrite (LWW)
    private func forceOverwrite() async {
        guard let id = recipeId else { return }

        let baseRevision = conflictRecipe?.revision ?? expectedRevision

        let cleanIngredients = ingredients
            .map {
                RecipeIngredient(
                    id: $0.id,
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    quantity: $0.quantity.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.name.isEmpty }

        let updated = Recipe(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            tags: Array(tags),
            createdAt: conflictRecipe?.createdAt ?? Date(),
            updatedAt: Date(),
            revision: baseRevision
        )

        do {
            try await vm.updateRecipe(
                recipe: updated,
                ingredients: cleanIngredients,
                expectedRevision: baseRevision
            )
            dismiss()
        } catch {
            print("❌ Force overwrite failed:", error)
        }
    }
}
