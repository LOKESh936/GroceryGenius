import SwiftUI

struct GroceryListView: View {

    @StateObject private var viewModel = GroceryViewModel()

    @State private var name: String = ""
    @State private var quantity: String = ""

    // For editing via sheet
    @State private var editingItem: GroceryItem?

    var body: some View {
        ZStack {
            // App-wide background
            AppColor.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {

                // Title is provided by NavigationStack in ContentView
                // so just ensure we use the correct display mode there.
                // (keep this here in case GroceryListView is used standalone)
                Text("Grocery List")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColor.primary)
                    .padding(.top, 8)

                // MARK: - Input Fields
                HStack(spacing: 12) {
                    TextField("Item name", text: $name)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)

                    TextField("Qty", text: $quantity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                        .frame(width: 90)

                    Button {
                        viewModel.addItem(name: name, quantity: quantity)
                        name = ""
                        quantity = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(AppColor.accent)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15),
                                    radius: 6, x: 0, y: 4)
                    }
                }

                // Column headers
                HStack {
                    Text("Item name")
                        .font(.subheadline)
                        .foregroundColor(AppColor.primary.opacity(0.8))
                    Spacer()
                    Text("Qty")
                        .font(.subheadline)
                        .foregroundColor(AppColor.primary.opacity(0.8))
                }
                .padding(.top, 4)

                // MARK: - List
                List {
                    ForEach(viewModel.items) { item in
                        GroceryRowView(item: item) {
                            viewModel.toggleCompletion(for: item.id)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                            // DELETE (leftmost, red)
                            Button(role: .destructive) {
                                viewModel.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            // EDIT (next to delete)
                            Button {
                                editingItem = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Grocery List")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editingItem) { item in
            EditGrocerySheet(item: item) { newName, newQuantity in
                viewModel.update(itemID: item.id,
                                 name: newName,
                                 quantity: newQuantity)
            }
        }
    }
}

// MARK: - Edit Sheet

struct EditGrocerySheet: View {
    let item: GroceryItem
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: String

    init(item: GroceryItem, onSave: @escaping (String, String) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item")) {
                    TextField("Name", text: $name)
                }

                Section(header: Text("Quantity")) {
                    TextField("e.g. 2 Lbs", text: $quantity)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, quantity)
                        dismiss()
                    }
                }
            }
        }
    }
}
