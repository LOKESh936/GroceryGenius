import FirebaseFirestore

final class RecipeStore {

    private let db = Firestore.firestore()

    func loadRecipes(uid: String) async throws -> [Recipe] {
        let snap = try await db
            .collection(FirestorePaths.recipes(uid: uid))
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snap.documents.compactMap {
            try? $0.data(as: Recipe.self)
        }
    }

    func createRecipe(uid: String, recipe: Recipe) async throws {
        try db
            .collection(FirestorePaths.recipes(uid: uid))
            .document(recipe.id)
            .setData(from: recipe)
    }

    func deleteRecipe(uid: String, id: String) async throws {
        try await db
            .collection(FirestorePaths.recipes(uid: uid))
            .document(id)
            .delete()
    }
}
