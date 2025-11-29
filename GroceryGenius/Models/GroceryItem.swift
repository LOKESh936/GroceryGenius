import Foundation

struct GroceryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: String
    var isCompleted: Bool

    // Custom init so old call sites still work
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

