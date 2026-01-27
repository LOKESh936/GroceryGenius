import Foundation
import FirebaseFirestore

final class RecipesStore {

    private let db = Firestore.firestore()

    // MARK: - Paths
    private func recipesRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("recipes")
    }

    private func recipeRef(uid: String, id: String) -> DocumentReference {
        recipesRef(uid: uid).document(id)
    }

    private func ingredientsRef(uid: String, recipeId: String) -> CollectionReference {
        recipeRef(uid: uid, id: recipeId).collection("ingredients")
    }

    // MARK: - Live sync
    func listenRecipes(
        uid: String,
        onChange: @escaping ([Recipe]) -> Void
    ) -> ListenerRegistration {
        recipesRef(uid: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snap, _ in
                let items = snap?.documents.compactMap {
                    try? $0.data(as: Recipe.self)
                } ?? []
                onChange(items)
            }
    }

    // MARK: - Ingredients
    func fetchIngredients(uid: String, recipeId: String) async throws -> [RecipeIngredient] {
        let snap = try await ingredientsRef(uid: uid, recipeId: recipeId)
            .order(by: "name")
            .getDocuments()

        return snap.documents.compactMap {
            try? $0.data(as: RecipeIngredient.self)
        }
    }

    // MARK: - Batch create / update
    func batchUpsertRecipe(
        uid: String,
        recipe: Recipe,
        ingredients: [RecipeIngredient]
    ) async throws {

        let batch = db.batch()

        let rRef = recipeRef(uid: uid, id: recipe.id)
        try batch.setData(from: recipe, forDocument: rRef, merge: true)

        let existing = try await ingredientsRef(uid: uid, recipeId: recipe.id).getDocuments()
        for doc in existing.documents {
            batch.deleteDocument(doc.reference)
        }

        for ing in ingredients {
            let iRef = ingredientsRef(uid: uid, recipeId: recipe.id).document(ing.id)
            try batch.setData(from: ing, forDocument: iRef)
        }

        try await batch.commit()
    }

    // MARK: - Transaction update (revision check)
    enum ConflictError: Error {
        case conflict(current: Recipe)
    }

    func transactionUpdateRecipe(
        uid: String,
        recipe: Recipe,
        ingredients: [RecipeIngredient],
        expectedRevision: Int
    ) async throws {

        let rRef = recipeRef(uid: uid, id: recipe.id)

        try await db.runTransaction { tx, errorPointer in
            do {
                let snap = try tx.getDocument(rRef)
                let current = try snap.data(as: Recipe.self)

                guard current.revision == expectedRevision else {
                    errorPointer?.pointee = NSError(
                        domain: "RecipesConflict",
                        code: 409
                    )
                    return nil
                }

                var updated = recipe
                updated.revision += 1
                updated.updatedAt = Date()

                try tx.setData(from: updated, forDocument: rRef, merge: true)
                return nil

            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        // Ingredients handled AFTER transaction
        try await batchUpsertRecipe(uid: uid, recipe: recipe, ingredients: ingredients)
    }

    // MARK: - Delete
    func deleteRecipe(uid: String, recipeId: String) async throws {
        let batch = db.batch()

        let rRef = recipeRef(uid: uid, id: recipeId)
        batch.deleteDocument(rRef)

        let ingSnap = try await ingredientsRef(uid: uid, recipeId: recipeId).getDocuments()
        for doc in ingSnap.documents {
            batch.deleteDocument(doc.reference)
        }

        try await batch.commit()
    }
}
