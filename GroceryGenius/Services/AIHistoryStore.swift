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

    func saveMessage(
        uid: String,
        conversationId: String,
        message: AIMsg
    ) async throws {

        let convoRef = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        // Always bump updatedAt when a message is saved
        try await convoRef.setData([
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)

        try await convoRef
            .collection("messages")
            .document(message.id)
            .setData([
                "text": message.text,
                "isUser": message.isUser,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    func clearConversation(
        uid: String,
        conversationId: String,
        messages: [AIMsg]
    ) async throws {

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

    /// Creates a new conversation with auto-generated id
    func createConversation(uid: String, title: String) async throws -> String {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document()

        try await ref.setData([
            "title": title,
            "lastMessage": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return ref.documentID
    }

    /// Ensures the conversation doc exists (important when activeConversationId is a fresh UUID stored in UserDefaults).
    func ensureConversationExists(
        uid: String,
        conversationId: String,
        titleIfMissing: String
    ) async throws {

        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        let snap = try await ref.getDocument()
        if snap.exists { return }

        try await ref.setData([
            "title": titleIfMissing,
            "lastMessage": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func loadConversations(uid: String) async throws -> [AIConversation] {
        let ref = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .order(by: "updatedAt", descending: true)

        let snapshot = try await ref.getDocuments()

        return snapshot.documents.compactMap { doc -> AIConversation? in
            let data = doc.data()

            guard let title = data["title"] as? String else {
                return nil
            }

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let lastMessage = data["lastMessage"] as? String ?? ""

            return AIConversation(
                id: doc.documentID,
                title: title,
                lastMessage: lastMessage,
                createdAt: createdAt
            )
        }
    }

    func updateConversationMetadata(
        uid: String,
        conversationId: String,
        title: String? = nil,
        lastMessage: String? = nil
    ) async throws {

        var update: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let title { update["title"] = title }
        if let lastMessage { update["lastMessage"] = lastMessage }

        try await db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)
            .updateData(update)
    }

    func deleteConversation(uid: String, conversationId: String) async throws {
        let convoRef = db.collection("users")
            .document(uid)
            .collection("aiMeals")
            .document(conversationId)

        let messages = try await convoRef.collection("messages").getDocuments()

        let batch = db.batch()
        messages.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(convoRef)

        try await batch.commit()
    }
}
