import Foundation
import FirebaseFirestore

final class AIHistoryStore {

    private let db = Firestore.firestore()

    // MARK: - Messages

    func loadMessages(uid: String, conversationId: String) async throws -> [AIMsg] {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)

        let snapshot = try await ref.getDocuments()

        return snapshot.documents.map { doc in
            let data = doc.data()
            return AIMsg(
                id: doc.documentID,
                text: data["text"] as? String ?? "",
                isUser: data["isUser"] as? Bool ?? false
            )
        }
    }

    func saveMessage(uid: String, conversationId: String, message: AIMsg) async throws {
        let base = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        try await base.setData([
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)

        try await base.collection("messages")
            .document(message.id)
            .setData([
                "text": message.text,
                "isUser": message.isUser,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    // ✅ FIXED: clearConversation was deleting wrong doc ids before
    func clearConversation(uid: String, conversationId: String, messages: [AIMsg]) async throws {
        let batch = db.batch()
        let base = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)
            .collection("messages")

        for msg in messages {
            batch.deleteDocument(base.document(msg.id))
        }

        try await batch.commit()
    }

    // MARK: - Conversations

    func ensureConversationDocument(uid: String, conversationId: String, title: String) async throws {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        let snap = try await ref.getDocument()
        if snap.exists { return }

        try await ref.setData([
            "title": title,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func createConversation(uid: String, title: String) async throws -> String {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document()

        try await ref.setData([
            "title": title,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return ref.documentID
    }

    func loadConversations(uid: String) async throws -> [AIConversation] {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .order(by: "updatedAt", descending: true)

        let snapshot = try await ref.getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let title = data["title"] as? String else { return nil }

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            return AIConversation(
                id: doc.documentID,
                title: title,
                createdAt: createdAt
            )
        }
    }

    // ✅ NEW: delete conversation + all messages
    func deleteConversation(uid: String, conversationId: String) async throws {
        let convoRef = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        let messagesRef = convoRef.collection("messages")

        // 1) delete all messages (batched)
        let messagesSnapshot = try await messagesRef.getDocuments()

        if !messagesSnapshot.documents.isEmpty {
            let batch = db.batch()
            for doc in messagesSnapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
        }

        // 2) delete conversation doc
        try await convoRef.delete()
    }
}
