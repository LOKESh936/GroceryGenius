import Foundation

struct AIMsg: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let isUser: Bool

    init(id: String = UUID().uuidString, text: String, isUser: Bool) {
        self.id = id
        self.text = text
        self.isUser = isUser
    }
}
