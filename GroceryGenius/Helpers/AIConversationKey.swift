import Foundation

enum AIConversationKey {
    static func key(for uid: String) -> String {
        "ai_conversation_id_\(uid)"
    }
}
