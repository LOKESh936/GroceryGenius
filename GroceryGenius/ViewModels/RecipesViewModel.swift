import Foundation
import FirebaseAuth
import FirebaseFirestore

final class RecipesViewModel: ObservableObject {

    @Published private(set) var recipes: [Recipe] = []

    private let store = RecipesStore()
    private var listener: ListenerRegistration?

    private var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listener?.remove() }

    // MARK: - Live sync
    func startListening() {
        guard let uid else { return }

        listener?.remove()
        listener = store.listenRecipes(uid: uid) { [weak self] items in
            Task { @MainActor in
                self?.recipes = items
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Create
    func createRecipe(
        title: String,
        notes: String,
        tags: [RecipeTag],
        ingredients: [RecipeIngredient]
    ) async throws {

        guard let uid else { return }

        let recipe = Recipe(title: title, notes: notes, tags: tags)

        await MainActor.run {
            recipes.insert(recipe, at: 0)
        }

        do {
            try await store.batchUpsertRecipe(
                uid: uid,
                recipe: recipe,
                ingredients: ingredients
            )
        } catch {
            await MainActor.run {
                recipes.removeAll { $0.id == recipe.id }
            }
            throw error
        }
    }

    // MARK: - Update
    func updateRecipe(
        recipe: Recipe,
        ingredients: [RecipeIngredient],
        expectedRevision: Int
    ) async throws {

        guard let uid else { return }

        await MainActor.run {
            if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[idx] = recipe
            }
        }

        try await store.transactionUpdateRecipe(
            uid: uid,
            recipe: recipe,
            ingredients: ingredients,
            expectedRevision: expectedRevision
        )
    }

    // MARK: - Delete
    func deleteRecipe(_ recipe: Recipe) async {
        guard let uid else { return }

        let snapshot = recipes

        await MainActor.run {
            recipes.removeAll { $0.id == recipe.id }
        }

        do {
            try await store.deleteRecipe(uid: uid, recipeId: recipe.id)
        } catch {
            await MainActor.run {
                recipes = snapshot
            }
        }
    }

    // MARK: - Ingredients
    func loadIngredients(recipeId: String) async -> [RecipeIngredient] {
        guard let uid else { return [] }
        return (try? await store.fetchIngredients(uid: uid, recipeId: recipeId)) ?? []
    }
}
