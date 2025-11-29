import SwiftUI

class GroceryViewModel: ObservableObject {
    @Published var items: [GroceryItem] = [] {
        didSet {
            saveItems()
        }
    }
    
    private let storageKey = "grocery_items_v1"
    
    init() {
        loadItems()
    }
    
    // MARK: - CRUD
    
    func addItem(name: String, quantity: String) {
        let newItem = GroceryItem(name: name, quantity: quantity)
        items.append(newItem)
    }
    
    func deleteItem(indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
    }
    
    func toggleItem(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
        }
    }
    
    // MARK: - Persistence (UserDefaults + JSON)
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save grocery items:", error)
        }
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([GroceryItem].self, from: data)
            items = decoded
        } catch {
            print("❌ Failed to load grocery items:", error)
        }
    }
}
