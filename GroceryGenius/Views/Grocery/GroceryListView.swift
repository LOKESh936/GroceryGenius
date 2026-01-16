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
    @State private var historySheet: HistorySheet?
    @StateObject private var historyVM = GroceryHistoryViewModel()

    // MARK: - Scroll behavior
    @State private var hideCompletedButton = false
    @State private var lastScrollOffset: CGFloat = 0

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

    // ✅ True source of truth
    private var allItemsCompleted: Bool {
        !viewModel.items.isEmpty &&
        viewModel.items.allSatisfy { $0.isCompleted }
    }

    private func resetCompletedButtonVisibility() {
        hideCompletedButton = false
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {

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

                // MARK: - Bottom Actions
                Spacer(minLength: 0)

                HStack(spacing: 12) {

                    // 🔹 CLEAR ALL (ALWAYS)
                    Button {
                        viewModel.clearAll()
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColor.cardBackground.opacity(0.6))
                            .clipShape(Capsule())
                    }

                    // 🔹 COMPLETED (CONDITIONAL)
                    if allItemsCompleted {
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
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .background(
                            Capsule()
                                .fill(AppColor.primary)
                                .shadow(
                                    color: Color.black.opacity(0.18),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .opacity(hideCompletedButton ? 0 : 1)
                        .offset(y: hideCompletedButton ? 40 : 0)
                        .animation(.easeInOut(duration: 0.25), value: hideCompletedButton)
                        .onAppear { resetCompletedButtonVisibility() }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Groceries")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ TOOLBAR (UNCHANGED BEHAVIOR)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    historySheet = HistorySheet()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .foregroundStyle(AppColor.primary)

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

        // ✅ EDIT SHEET
        .sheet(item: $editingItem) { item in
            EditGrocerySheet(item: item) { newName, newQty in
                viewModel.update(
                    itemID: item.id,
                    name: newName,
                    quantity: newQty
                )
            }
        }

        // ✅ HISTORY SHEET (FIXED LOCATION)
        .sheet(item: $historySheet) { _ in
            GroceryHistoryView()
                .environmentObject(historyVM)
        }

        // ✅ CONFIRM CLEAR
        .confirmationDialog(
            "Clear all items?",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        }

        .onTapGesture { hideKeyboard() }
    }

    // MARK: - List
    private var listContent: some View {
        List {

            // ACTIVE
            if !activeItems.isEmpty {
                Section {
                    ForEach(activeItems) { item in
                        GroceryRowView(item: item) {
                            viewModel.toggleCompletion(for: item.id)
                        }
                        .listRowBackground(Color.clear)
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

            // COMPLETED
            if !completedItems.isEmpty {
                Section {
                    if showCompleted {
                        ForEach(completedItems) { item in
                            GroceryRowView(item: item) {
                                viewModel.toggleCompletion(for: item.id)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                } header: {
                    completedHeader
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        lastScrollOffset = geo.frame(in: .global).minY
                    }
                    .onChange(of: geo.frame(in: .global).minY) {
                        let newValue = geo.frame(in: .global).minY
                        let delta = newValue - lastScrollOffset
                        lastScrollOffset = newValue
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hideCompletedButton = delta < 0
                        }
                    }
            }
        )
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowSeparator(.hidden)
        .background(Color.clear)
    }

    // MARK: - Headers
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
            withAnimation(.easeInOut(duration: 0.2)) {
                showCompleted.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Completed (\(completedItems.count))")
                Spacer()
                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColor.primary)
        }
        .buttonStyle(.plain)
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
        RoundedRectangle(cornerRadius: 14)
            .fill(AppColor.cardBackground.opacity(0.55))
    }

    private var fieldStroke: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
    }

    // MARK: - Add Row
    private var addRow: some View {
        HStack(spacing: 12) {
            // Name field
            HStack {
                TextField("Add item", text: $name)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .name)
                    .foregroundStyle(AppColor.primary)
                    .padding(12)
            }
            .background(fieldBackground)
            .overlay(fieldStroke)

            // Qty field
            HStack {
                TextField("Qty", text: $quantity)
                    .keyboardType(.numbersAndPunctuation)
                    .focused($focusedField, equals: .qty)
                    .foregroundStyle(AppColor.primary)
                    .padding(12)
            }
            .frame(minWidth: 70, maxWidth: 110)
            .background(fieldBackground)
            .overlay(fieldStroke)

            // Add button
            Button {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedQty = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }
                viewModel.addItem(name: trimmedName, quantity: trimmedQty)
                name = ""
                quantity = ""
                focusedField = .name
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.primary.opacity(0.8))
            TextField("Search items", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(AppColor.primary)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.primary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(fieldBackground)
        .overlay(fieldStroke)
    }
    private struct HistorySheet: Identifiable {
        let id = UUID()
    }

}
