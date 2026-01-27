import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var notes: String
    var tags: [RecipeTag]
    let createdAt: Date
    var updatedAt: Date
    var revision: Int

    init(
        id: String = UUID().uuidString,
        title: String,
        notes: String,
        tags: [RecipeTag] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        revision: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revision = revision
    }
}
