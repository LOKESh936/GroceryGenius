import Foundation

struct RecipeIngredient: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: String
    var sortIndex: Int  

    init(
        id: String = UUID().uuidString,
        name: String = "",
        quantity: String = "",
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.sortIndex = sortIndex
    }
}
