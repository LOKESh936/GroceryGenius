import Foundation
import FirebaseFirestore

final class GroceryStore {

    private let db = Firestore.firestore()

    // MARK: - Listener

    func listenGroceries(
        uid: String,
        onChange: @escaping ([GroceryItem]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {

        let ref = db.collection("users")
            .document(uid)
            .collection("groceries")
            .order(by: "createdAt", descending: false)

        return ref.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            guard let snapshot else {
                onChange([])
                return
            }

            let items: [GroceryItem] = snapshot.documents.compactMap { doc in
                let data = doc.data()

                let name = (data["name"] as? String) ?? ""
                let quantity = (data["quantity"] as? String) ?? ""
                let isCompleted = (data["isCompleted"] as? Bool) ?? false

                // docId = UUID string
                let uuid = UUID(uuidString: doc.documentID) ?? UUID()

                return GroceryItem(id: uuid, name: name, quantity: quantity, isCompleted: isCompleted)
            }

            onChange(items)
        }
    }

    // MARK: - Write helpers

    func addItem(uid: String, item: GroceryItem) async throws {
        let docRef = db.collection("users").document(uid).collection("groceries").document(item.id.uuidString)

        let now = FieldValue.serverTimestamp()
        try await docRef.setData([
            "name": item.name,
            "quantity": item.quantity,
            "isCompleted": item.isCompleted,
            "createdAt": now,
            "updatedAt": now
        ], merge: true)
    }

    func updateItem(uid: String, item: GroceryItem) async throws {
        let docRef = db.collection("users").document(uid).collection("groceries").document(item.id.uuidString)
        try await docRef.setData([
            "name": item.name,
            "quantity": item.quantity,
            "isCompleted": item.isCompleted,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func deleteItem(uid: String, itemID: UUID) async throws {
        let docRef = db.collection("users").document(uid).collection("groceries").document(itemID.uuidString)
        try await docRef.delete()
    }

    func clearAll(uid: String, items: [GroceryItem]) async throws {
        let batch = db.batch()
        let base = db.collection("users").document(uid).collection("groceries")
        for item in items {
            batch.deleteDocument(base.document(item.id.uuidString))
        }
        try await batch.commit()
    }
}
