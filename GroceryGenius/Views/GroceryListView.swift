import SwiftUI

struct GroceryListView: View {
    @StateObject private var viewModel = GroceryViewModel()
    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var editingItem: GroceryItem? = nil
    @State private var editName: String = ""
    @State private var editQuantity: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Global screen background – matches the rest of the app
                AppColor.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Input section
                    HStack(spacing: 12) {
                        TextField("Item name", text: $name)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.95))   // small white chip
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)

                        TextField("Qty", text: $quantity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                            .frame(width: 80)

                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }

                            viewModel.addItem(name: trimmed, quantity: quantity)
                            name = ""
                            quantity = ""
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(AppColor.accent)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    // MARK: - Column header
                    HStack {
                        Text("Item name")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColor.primary.opacity(0.7))

                        Spacer()

                        Text("Qty")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColor.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                    // MARK: - List
                    List {
                        ForEach(viewModel.items) { item in
                            GroceryRowView(item: item, viewModel: viewModel)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)       // don’t override bg
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        // Prepare and present edit sheet
                                        editingItem = item
                                        editName = item.name
                                        editQuantity = item.quantity
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)

                                    Button(role: .destructive) {
                                        // Trigger same deletion logic as .onDelete using the item's index
                                        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.deleteItem(indexSet: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: viewModel.deleteItem)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)               // hide default gray
                    .background(Color.clear)                       // let ZStack show
                    .sheet(item: $editingItem) { item in
                        NavigationStack {
                            Form {
                                Section(header: Text("Edit Item")) {
                                    TextField("Item name", text: $editName)
                                    TextField("Qty", text: $editQuantity)
                                }
                            }
                            .navigationTitle("Edit")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { editingItem = nil }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Save") {
                                        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !trimmed.isEmpty else { return }
                                        // Attempt to update via viewModel method; fallback to direct mutation
                                        if let idx = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.items[idx].name = trimmed
                                            viewModel.items[idx].quantity = editQuantity
                                        }
                                        editingItem = nil
                                    }
                                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

