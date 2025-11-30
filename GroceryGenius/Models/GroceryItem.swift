import Foundation

struct GroceryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        quantity: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isCompleted = isCompleted
    }
}
