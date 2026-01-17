import Foundation

struct RecipeIngredient: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: String

    init(id: String = UUID().uuidString, name: String, quantity: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}
