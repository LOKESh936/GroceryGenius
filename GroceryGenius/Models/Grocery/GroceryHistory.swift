import Foundation

struct GroceryHistory: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    let completedAt: Date
    let items: [GroceryItem]
}
