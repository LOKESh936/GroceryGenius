import SwiftUI

struct RecipesView: View {

    @State private var searchText: String = ""
    @State private var sort: Sort = .recent
    @State private var showNewRecipeSheet = false

    @State private var recipes: [RecipeUIModel] = RecipeUIModel.sample

    enum Sort: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case aToZ = "A–Z"

        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .recent: return "clock"
            case .aToZ:   return "textformat"
            }
        }
    }

    private var filtered: [RecipeUIModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = q.isEmpty ? recipes : recipes.filter {
            $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }

        switch sort {
        case .recent:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .aToZ:
            return base.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 14) {

                GGCard {
                    VStack(alignment: .leading, spacing: 12) {

                        HStack {
                            Text("Recipes")
                                .font(AppFont.title(22))
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer()

                            Menu {
                                ForEach(Sort.allCases) { option in
                                    Button {
                                        Haptic.light()
                                        sort = option
                                    } label: {
                                        Label(option.rawValue, systemImage: option.systemImage)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColor.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(AppColor.chromeSurface))
                            }

                            Button {
                                Haptic.medium()
                                showNewRecipeSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 42, height: 42)
                                    .background(AppColor.accent)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                            }
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppColor.primary.opacity(0.75))

                            TextField("Search recipes", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(AppColor.textPrimary)
                                .submitLabel(.done)
                                .onSubmit { hideKeyboard() }

                            if !searchText.isEmpty {
                                Button {
                                    Haptic.light()
                                    searchText = ""
                                    hideKeyboard()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(AppColor.primary.opacity(0.45))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(AppColor.cardBackground.opacity(0.65))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if filtered.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                    Spacer()
                } else {
                    list
                }
            }
        }
        // ✅ tap anywhere dismiss keyboard
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showNewRecipeSheet) {
            NewRecipeSheetView()
        }
    }

    private var emptyState: some View {
        GGCard {
            VStack(alignment: .leading, spacing: 10) {

                Text("No recipes yet")
                    .font(AppFont.subtitle(17))
                    .foregroundStyle(AppColor.textPrimary)

                Text("Create your first recipe, or later we’ll add saving from AI meals.")
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textSecondary)

                Button {
                    Haptic.medium()
                    hideKeyboard()
                    showNewRecipeSheet = true
                } label: {
                    Text("Create Recipe")
                        .font(AppFont.subtitle(15))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(AppColor.primary)
                                .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(filtered) { recipe in
                RecipeRow(recipe: recipe)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
                                recipes.remove(at: idx)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            // edit later
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(AppColor.primary)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.clear)
        .dismissKeyboardOnTap()
    }
}

private struct RecipeRow: View {
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
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(recipe.subtitle)
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)

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

private struct RecipeUIModel: Identifiable {
    let id: String
    var title: String
    var subtitle: String
    var createdAt: Date

    static let sample: [RecipeUIModel] = [
        .init(id: UUID().uuidString, title: "Chicken Rice Bowl", subtitle: "20 min • high protein", createdAt: Date().addingTimeInterval(-86_000)),
        .init(id: UUID().uuidString, title: "Paneer Wrap", subtitle: "15 min • quick", createdAt: Date().addingTimeInterval(-200_000)),
        .init(id: UUID().uuidString, title: "Oats + Banana", subtitle: "5 min • breakfast", createdAt: Date().addingTimeInterval(-400_000))
    ]
}

#Preview {
    RecipesView()
}
