import Foundation

enum FirestorePaths {
    static func groceries(uid: String) -> String {
        "users/\(uid)/groceries"
    }
}
