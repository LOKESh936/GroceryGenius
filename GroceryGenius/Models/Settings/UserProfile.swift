import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {

    @DocumentID var id: String?

    let uid: String
    let email: String

    let displayName: String?
    let photoURL: String?   
}
