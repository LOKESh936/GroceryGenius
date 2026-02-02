import Foundation

struct SavedAccount: Identifiable, Codable, Equatable {
    let id: String        
    var email: String
    var displayName: String?
    var faceIDEnabled: Bool
}
