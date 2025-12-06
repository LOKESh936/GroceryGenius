import Foundation

@MainActor
final class GroceryViewModel: ObservableObject {

    @Published var items: [GroceryItem] = []

    private let storageKey = "grocery_items_v1"

    init() {
        loadItems()
    }

    // MARK: - Public API

    func addItem(name: String, quantity: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newItem = GroceryItem(name: trimmedName,
                                  quantity: quantity.trimmingCharacters(in: .whitespacesAndNewlines))
        items.append(newItem)
        saveItems()
    }

    func toggleCompletion(for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        saveItems()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func delete(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            saveItems()
        }
    }

    func update(itemID: UUID, name: String, quantity: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        items[index].name = trimmedName
        items[index].quantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        saveItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }

    // MARK: - Persistence

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([GroceryItem].self, from: data)
            self.items = decoded
        } catch {
            print("❌ Failed to decode grocery items:", error)
        }
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to encode grocery items:", error)
        }
    }
}
