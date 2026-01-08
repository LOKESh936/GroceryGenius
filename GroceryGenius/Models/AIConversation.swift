import Foundation

struct AIConversation: Identifiable, Hashable {
    let id: String
    let title: String
    let lastMessage: String
    let createdAt: Date
}
