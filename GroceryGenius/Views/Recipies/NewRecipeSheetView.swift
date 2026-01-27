import SwiftUI

struct NewRecipeSheetView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var recipesVM: RecipesViewModel

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedTags: Set<RecipeTag> = []

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 16) {

                    // MARK: - Header
                    SectionHeader(
                        title: "New Recipe",
                        subtitle: "Create a recipe to reuse later."
                    )
                    .padding(.top, 10)

                    // MARK: - Form
                    GGCard {
                        VStack(alignment: .leading, spacing: 14) {

                            // Title
                            Text("Recipe title")
                                .font(AppFont.caption(12))
                                .foregroundStyle(AppColor.textSecondary)

                            TextField("e.g., Chicken Rice Bowl", text: $title)
                                .font(AppFont.body(16))
                                .padding(12)
                                .background(AppColor.cardElevated)
                                .cornerRadius(12)
                                .focused($isTitleFocused)
                                .submitLabel(.next)
                                .onSubmit { isNotesFocused = true }

                            Divider().opacity(0.35)

                            // Notes
                            Text("Notes (optional)")
                                .font(AppFont.caption(12))
                                .foregroundStyle(AppColor.textSecondary)

                            TextEditor(text: $notes)
                                .font(.system(size: 15, design: .rounded))
                                .frame(minHeight: 120)
                                .padding(10)
                                .background(AppColor.cardElevated)
                                .cornerRadius(12)
                                .focused($isNotesFocused)

                            Divider().opacity(0.35)

                            // Tags
                            Text("Tags")
                                .font(AppFont.caption(12))
                                .foregroundStyle(AppColor.textSecondary)

                            tagsRow
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // MARK: - Create
                    Button {
                        createRecipe()
                    } label: {
                        Text("Create Recipe")
                            .font(AppFont.subtitle(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(isValid ? AppColor.primary : AppColor.primary.opacity(0.45))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    // MARK: - Tags Row
    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecipeTag.allCases) { tag in
                    tagChip(tag)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tagChip(_ tag: RecipeTag) -> some View {
        let isSelected = selectedTags.contains(tag)

        return Button {
            Haptic.light()
            if isSelected {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tag.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(tag.title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppColor.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AppColor.primary : AppColor.chromeSurface.opacity(0.85))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create
    private func createRecipe() {
        guard isValid else { return }

        hideKeyboard()
        Haptic.medium()

        Task {
            do {
                try await recipesVM.createRecipe(
                    title: title,
                    notes: notes,
                    tags: Array(selectedTags),
                    ingredients: [] // ingredients added later
                )
                dismiss()
            } catch {
                // TODO: Surface this error to the user if desired
                print("Failed to create recipe: \(error)")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    NewRecipeSheetView()
        .environmentObject(RecipesViewModel())
}
