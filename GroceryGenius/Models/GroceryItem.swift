import Foundation

struct GroceryItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: String
    var isCompleted: Bool = false
}
