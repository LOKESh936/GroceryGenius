import Foundation
import FirebaseAuth

@MainActor
final class AccountStore: ObservableObject {

    static let shared = AccountStore()

    @Published private(set) var accounts: [SavedAccount] = []
    @Published var selectedAccount: SavedAccount?

    private let key = "gg_saved_accounts"

    private init() {
        load()
    }

    // MARK: - Save Current User

    func saveCurrentUser() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        if let index = accounts.firstIndex(where: { $0.id == user.uid }) {
            // 🔁 Update existing account
            accounts[index].email = email
            accounts[index].displayName = user.displayName
            selectedAccount = accounts[index]
        } else {
            // ➕ Insert new account
            let account = SavedAccount(
                id: user.uid,        
                email: user.email ?? "",
                displayName: user.displayName,
                faceIDEnabled: false
            )
            accounts.append(account)
            selectedAccount = account
        }

        persist()
    }

    // MARK: - Actions

    func removeAccount(_ account: SavedAccount) {
        accounts.removeAll { $0.id == account.id }
        persist()
    }

    func toggleFaceID(for account: SavedAccount, enabled: Bool) {
        guard let index = accounts.firstIndex(of: account) else { return }
        accounts[index].faceIDEnabled = enabled
        persist()
    }

    func select(_ account: SavedAccount) {
        selectedAccount = account
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(accounts) {
            KeychainService.save(data, key: key)
        }
    }

    private func load() {
        guard let data = KeychainService.load(key: key),
              let decoded = try? JSONDecoder().decode([SavedAccount].self, from: data)
        else { return }

        accounts = decoded
    }
}
