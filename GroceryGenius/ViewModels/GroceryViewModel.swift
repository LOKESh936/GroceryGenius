import SwiftUI

class GroceryViewModel: ObservableObject {
    @Published var items: [GroceryItem] = []
    
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
}
