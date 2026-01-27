import Foundation

struct RecipeUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let createdAt: Date
    let tags: [RecipeTag]

    init(recipe: Recipe) {
        self.id = recipe.id
        self.title = recipe.title
        self.createdAt = recipe.createdAt
        self.tags = recipe.tags

        self.subtitle = recipe.notes.isEmpty
            ? "Saved recipe"
            : recipe.notes
    }
}
