import Foundation
import FirebaseFirestore

final class GroceryHistoryStore {

    private let db = Firestore.firestore()

    private func base(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("groceryHistory")
    }

    func saveHistory(uid: String, history: GroceryHistory) async throws {
        try await base(uid: uid)
            .document(history.id)
            .setData([
                "title": history.title,
                "completedAt": Timestamp(date: history.completedAt),
                "items": history.items.map {
                    [
                        "name": $0.name,
                        "quantity": $0.quantity,
                        "isCompleted": $0.isCompleted
                    ]
                }
            ])
    }

    func loadHistory(uid: String) async throws -> [GroceryHistory] {
        let snap = try await base(uid: uid)
            .order(by: "completedAt", descending: true)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()
            let title = data["title"] as? String ?? "Shopping"
            let completedAt = (data["completedAt"] as? Timestamp)?.dateValue() ?? Date()
            let itemsData = data["items"] as? [[String: Any]] ?? []

            let items = itemsData.map {
                GroceryItem(
                    name: $0["name"] as? String ?? "",
                    quantity: $0["quantity"] as? String ?? "",
                    isCompleted: false
                )
            }

            return GroceryHistory(
                id: doc.documentID,
                title: title,
                completedAt: completedAt,
                items: items
            )
        }
    }

    func deleteHistory(uid: String, id: String) async throws {
        try await base(uid: uid).document(id).delete()
    }

    func renameHistory(uid: String, id: String, title: String) async throws {
        try await base(uid: uid)
            .document(id)
            .updateData(["title": title])
    }
}
