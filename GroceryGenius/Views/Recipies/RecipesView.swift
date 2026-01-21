import SwiftUI

// MARK: - RecipesView
struct RecipesView: View {

    // UI state
    @State private var searchText = ""
    @State private var sort: Sort = .recent
    @State private var showNewRecipeSheet = false

    // Search focus + animations
    @FocusState private var isSearchFocused: Bool
    @State private var isCollapsed = false

    // Filters
    @State private var selectedFilters: Set<RecipeFilter> = []

    // Demo data (kept exactly as requested)
    @State private var recipes: [RecipeUIModel] = RecipeUIModel.sample

    enum Sort: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case aToZ = "A–Z"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .recent: return "clock"
            case .aToZ: return "textformat"
            }
        }
    }

    // MARK: - Filter + Search + Sort
    private var filtered: [RecipeUIModel] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        var base = q.isEmpty
            ? recipes
            : recipes.filter {
                $0.title.lowercased().contains(q) ||
                $0.subtitle.lowercased().contains(q)
            }

        if !selectedFilters.isEmpty {
            base = base.filter { recipe in
                Set(recipe.tags).isSuperset(of: selectedFilters)
            }
        }

        return sort == .recent
            ? base.sorted { $0.createdAt > $1.createdAt }
            : base.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(
                        spacing: 12,
                        pinnedViews: [.sectionHeaders]
                    ) {

                        Section(header: stickyHeader) {
                            content
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
            }
            .sheet(isPresented: $showNewRecipeSheet) {
                NewRecipeSheetView()
            }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            emptyState
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 200)
        } else {
            VStack(spacing: 12) {
                ForEach(filtered) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeRow(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Sticky Header
    private var stickyHeader: some View {
        VStack(spacing: isCollapsed ? 8 : 10) {
            searchBar
            filterChipsRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, isCollapsed ? 8 : 10)
        .background(
            AppColor.background
                .opacity(0.98)
                .overlay(
                    Rectangle()
                        .fill(AppColor.divider.opacity(0.6))
                        .frame(height: 0.5)
                        .opacity(isCollapsed ? 1 : 0),
                    alignment: .bottom
                )
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollYKey.self,
                    value: geo.frame(in: .global).minY
                )
            }
        )
        .onPreferenceChange(ScrollYKey.self) { minY in
            let shouldCollapse = minY < 120
            if shouldCollapse != isCollapsed {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCollapsed = shouldCollapse
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(AppColor.primary.opacity(0.75))

            TextField("Search recipes", text: $searchText)
                .font(.system(size: 15))
                .focused($isSearchFocused)
                .submitLabel(.done)
                .onSubmit { dismissSearch() }

            if !searchText.isEmpty && isSearchFocused {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.textSecondary.opacity(0.7))
                }
                .transition(.opacity)
            }

            Spacer(minLength: 8)

            Menu {
                ForEach(Sort.allCases) { option in
                    Button {
                        sort = option
                    } label: {
                        Label(option.rawValue, systemImage: option.systemImage)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColor.chromeSurface))
            }

            Button {
                dismissSearch()
                showNewRecipeSheet = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }

            if isSearchFocused {
                Button("Cancel") {
                    dismissSearch()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isCollapsed ? 9 : 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColor.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSearchFocused
                                ? AppColor.primary.opacity(0.35)
                                : AppColor.divider.opacity(0.7),
                            lineWidth: 0.8
                        )
                )
        )
    }

    private func dismissSearch() {
        hideKeyboard()
        isSearchFocused = false
    }

    // MARK: - Filter Chips
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecipeFilter.allCases) { chip in
                    FilterChip(
                        title: chip.title,
                        systemImage: chip.systemImage,
                        isSelected: selectedFilters.contains(chip)
                    ) {
                        if selectedFilters.contains(chip) {
                            selectedFilters.remove(chip)
                        } else {
                            selectedFilters.insert(chip)
                        }
                    }
                }

                if !selectedFilters.isEmpty {
                    Button("Clear") {
                        selectedFilters.removeAll()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(AppColor.chromeSurface.opacity(0.85))
                    )
                }
            }
            .padding(.vertical, isCollapsed ? 2 : 4)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        GGCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No recipes yet")
                    .font(AppFont.subtitle(16))

                Text("Create one, or save from AI Meals later.")
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textSecondary)

                Button("Create Recipe") {
                    showNewRecipeSheet = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(AppColor.primary))
            }
        }
    }
    private struct ScrollYKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    private struct FilterChip: View {
        let title: String
        let systemImage: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                    Text(title)
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
    }


}
