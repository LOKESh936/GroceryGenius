import SwiftUI

struct GroceryListView: View {

    @EnvironmentObject var viewModel: GroceryViewModel


    // MARK: - Add item
    @State private var name: String = ""
    @State private var quantity: String = ""

    // MARK: - Editing / dialogs
    @State private var editingItem: GroceryItem?
    @State private var showClearConfirmation = false

    // MARK: - Search / sections
    @State private var searchText: String = ""
    @State private var showCompleted: Bool = true

    // MARK: - History
    @State private var showHistory = false
    @StateObject private var historyVM = GroceryHistoryViewModel()

    // MARK: - Focus
    @FocusState private var focusedField: Field?
    enum Field { case name, qty }

    // MARK: - Filtering
    private var filteredItems: [GroceryItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return viewModel.items }
        return viewModel.items.filter {
            $0.name.lowercased().contains(q) ||
            $0.quantity.lowercased().contains(q)
        }
    }

    private var activeItems: [GroceryItem] {
        filteredItems.filter { !$0.isCompleted }
    }

    private var completedItems: [GroceryItem] {
        filteredItems.filter { $0.isCompleted }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Grocery List")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppColor.primary)
                    .padding(.top, 6)

                addRow
                searchBar

                HStack {
                    Text("Item name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.primary.opacity(0.75))
                    Spacer()
                    Text("Qty")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.primary.opacity(0.75))
                }

                if viewModel.items.isEmpty {
                    emptyState
                    Spacer()
                } else {
                    listContent
                }

                // ✅ COMPLETED BUTTON (NEW)
                if !viewModel.items.isEmpty {
                    Button {
                        Task {
                            let title = "Shopping – \(Date().formatted(date: .abbreviated, time: .omitted))"
                            await historyVM.saveFromCurrentList(
                                items: viewModel.items,
                                title: title
                            )
                            viewModel.clearAll()
                        }
                    } label: {
                        Text("Completed")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.plain)
                            .padding()
                            .background(AppColor.primary)   // ✅ matches theme
                            .clipShape(Capsule())
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Groceries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                // ✅ HISTORY BUTTON
                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .foregroundStyle(AppColor.primary)

                // EXISTING CLEAR BUTTON
                Button {
                    if !viewModel.items.isEmpty {
                        showClearConfirmation = true
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(
                    viewModel.items.isEmpty
                    ? AppColor.textSecondary.opacity(0.35)
                    : .red
                )
            }
        }
        .sheet(item: $editingItem) { item in
            EditGrocerySheet(item: item) { newName, newQty in
                viewModel.update(itemID: item.id, name: newName, quantity: newQty)
            }
        }
        .sheet(isPresented: $showHistory) {
            GroceryHistoryView()
                .environmentObject(historyVM)
        }
        .confirmationDialog(
            "Clear all items?",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearAll()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onTapGesture { hideKeyboard() }
        .onReceive(NotificationCenter.default.publisher(for: .openGroceryHistory)) { _ in
            showHistory = true
        }
        .sheet(isPresented: $showHistory) {
            GroceryHistoryView()
        }

    }

    // MARK: - Add Row
    private var addRow: some View {
        HStack(spacing: 12) {
            TextField("Item name", text: $name)
                .focused($focusedField, equals: .name)
                .padding(11)
                .background(fieldBackground)
                .overlay(fieldStroke)
                .cornerRadius(14)
                .onSubmit { focusedField = .qty }

            TextField("Qty", text: $quantity)
                .focused($focusedField, equals: .qty)
                .padding(11)
                .background(fieldBackground)
                .overlay(fieldStroke)
                .cornerRadius(14)
                .frame(width: 90)
                .onSubmit { addItem() }

            Button(action: addItem) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
        }
    }

    private func addItem() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.addItem(name: trimmed, quantity: quantity)
        name = ""
        quantity = ""
        searchText = ""
        focusedField = .name
    }

    // MARK: - Search
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search items…", text: $searchText)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(10)
        .background(fieldBackground)
        .overlay(fieldStroke)
        .cornerRadius(14)
    }

    // MARK: - List
    private var listContent: some View {
        List {
            if !activeItems.isEmpty {
                Section {
                    ForEach(activeItems) { item in
                        GroceryRowView(item: item) {
                            viewModel.toggleCompletion(for: item.id)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingItem = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppColor.primary)
                        }
                    }
                } header: {
                    sectionHeader("Active", activeItems.count, "cart.fill")
                }
            }

            if !completedItems.isEmpty {
                Section {
                    if showCompleted {
                        ForEach(completedItems) { item in
                            GroceryRowView(item: item) {
                                viewModel.toggleCompletion(for: item.id)
                            }
                        }
                    }
                } header: {
                    completedHeader
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListRowHeight, 0)
        .padding(.top, 2)
    }

    private func sectionHeader(_ title: String, _ count: Int, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text("\(title) (\(count))")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColor.primary)
    }

    private var completedHeader: some View {
        Button {
            Haptic.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                showCompleted.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.primary)

                Text("Completed (\(completedItems.count))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.primary)

                Spacer()

                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.primary.opacity(0.6))
            }
        }
        .padding(10)
        .buttonStyle(.plain)   // ✅ CRITICAL
        .textCase(nil)
        .listRowInsets(EdgeInsets()) // prevents layout jump
    }

    // MARK: - Empty
    private var emptyState: some View {
        Text("No items yet")
            .padding()
            .background(AppColor.cardBackground.opacity(0.55))
            .cornerRadius(18)
    }

    // MARK: - Fields
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14).fill(AppColor.cardBackground.opacity(0.55))
    }

    private var fieldStroke: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
    }
}

