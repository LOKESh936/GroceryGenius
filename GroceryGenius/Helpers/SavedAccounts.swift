import Foundation

enum SavedAccounts {
    static func store(email: String?) {
        guard let email, !email.isEmpty else { return }
        var arr = UserDefaults.standard.stringArray(forKey: "gg_saved_emails") ?? []
        arr.removeAll { $0.lowercased() == email.lowercased() }
        arr.insert(email, at: 0)
        arr = Array(arr.prefix(5)) // keep last 5
        UserDefaults.standard.set(arr, forKey: "gg_saved_emails")
    }
}
