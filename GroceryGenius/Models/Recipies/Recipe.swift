import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    let id: String
    var title: String
    var notes: String
    let createdAt: Date
}
