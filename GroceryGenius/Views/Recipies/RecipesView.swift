import SwiftUI

struct RecipesView: View {

    @EnvironmentObject private var vm: RecipesViewModel

    @State private var searchText = ""
    @State private var sort: Sort = .recent

    @FocusState private var isSearchFocused: Bool
    @State private var isCollapsed = false
    @State private var selectedTags: Set<RecipeTag> = []

    @State private var activeEditor: EditorRoute?

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

    enum EditorRoute: Identifiable {
        case create
        case edit(Recipe)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let r): return "edit-\(r.id)"
            }
        }
    }

    private var filtered: [Recipe] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        var base = q.isEmpty ? vm.recipes : vm.recipes.filter {
            $0.title.lowercased().contains(q) || $0.notes.lowercased().contains(q)
        }

        if !selectedTags.isEmpty {
            base = base.filter { Set($0.tags).isSuperset(of: selectedTags) }
        }

        switch sort {
        case .recent:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .aToZ:
            return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                        Section(header: stickyHeader) {
                            content
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
            }
            .sheet(item: $activeEditor) { route in
                switch route {
                case .create:
                    RecipeEditorSheetView(mode: .create)
                        .environmentObject(vm)

                case .edit(let recipe):
                    RecipeEditorSheetView(mode: .edit(recipe))
                        .environmentObject(vm)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            GGCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No recipes yet")
                        .font(AppFont.subtitle(16))
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Create one, or save from AI Meals later.")
                        .font(AppFont.body(14))
                        .foregroundStyle(AppColor.textSecondary)

                    Button {
                        Haptic.medium()
                        activeEditor = .create
                    } label: {
                        Text("Create Recipe")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(AppColor.primary))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 220)

        } else {
            VStack(spacing: 12) {
                ForEach(filtered) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                            .environmentObject(vm)
                    } label: {
                        RecipeRow(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { activeEditor = .edit(recipe) }

                        Button(role: .destructive) {
                            Task { await vm.deleteRecipe(recipe) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await vm.deleteRecipe(recipe) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            activeEditor = .edit(recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(AppColor.primary)
                    }
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
            tagChipsRow
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
                .buttonStyle(.plain)
                .transition(.opacity)
            }

            Spacer(minLength: 8)

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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColor.chromeSurface))
            }

            Button {
                Haptic.medium()
                dismissSearch()
                activeEditor = .create
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }

            if isSearchFocused {
                Button("Cancel") {
                    Haptic.light()
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColor.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSearchFocused
                            ? AppColor.primary.opacity(0.35)
                            : AppColor.divider.opacity(0.7),
                            lineWidth: 0.8
                        )
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.18), value: isCollapsed)
    }

    private func dismissSearch() {
        hideKeyboard()
        isSearchFocused = false
    }

    private var tagChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecipeTag.allCases) { tag in
                    TagChip(
                        title: tag.title,
                        systemImage: tag.systemImage,
                        isSelected: selectedTags.contains(tag)
                    ) {
                        Haptic.light()
                        if selectedTags.contains(tag) { selectedTags.remove(tag) }
                        else { selectedTags.insert(tag) }
                    }
                }

                if !selectedTags.isEmpty {
                    Button {
                        Haptic.light()
                        selectedTags.removeAll()
                    } label: {
                        Text("Clear")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppColor.chromeSurface.opacity(0.85)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, isCollapsed ? 2 : 4)
        }
        .animation(.easeInOut(duration: 0.18), value: isCollapsed)
    }
}

// MARK: - Components
private struct TagChip: View {
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
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : AppColor.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AppColor.primary : AppColor.chromeSurface.opacity(0.85))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ScrollYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
