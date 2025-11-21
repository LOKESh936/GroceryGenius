import Foundation

struct AIMsg: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
