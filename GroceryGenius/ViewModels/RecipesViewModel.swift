import FirebaseAuth

@MainActor
final class RecipesViewModel: ObservableObject {

    @Published var recipes: [Recipe] = []

    private let store = RecipeStore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    func load() async {
        guard let uid else { return }
        recipes = (try? await store.loadRecipes(uid: uid)) ?? []
    }

    func create(title: String, notes: String) async {
        guard let uid else { return }

        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let recipe = Recipe(
            id: UUID().uuidString,
            title: trimmed,
            notes: notes,
            createdAt: Date()
        )

        try? await store.createRecipe(uid: uid, recipe: recipe)
        await load()
    }

    func delete(_ recipe: Recipe) async {
        guard let uid else { return }
        try? await store.deleteRecipe(uid: uid, id: recipe.id)
        await load()
    }
}
