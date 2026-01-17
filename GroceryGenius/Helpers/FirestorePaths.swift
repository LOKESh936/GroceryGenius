import Foundation

enum FirestorePaths {
    static func groceries(uid: String) -> String {
        "users/\(uid)/groceries"
    }
    static func recipes(uid: String) -> String {
        "users/\(uid)/recipes"
    }
}
