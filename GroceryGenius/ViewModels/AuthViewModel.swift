import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var user: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var email: String = ""
    @Published var password: String = ""

    init() {
        self.user = Auth.auth().currentUser
        // Listen for changes (user logs in / logs out)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
            }
        }
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            print("🔥 FIREBASE ERROR:", error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp() async {
        errorMessage = nil
        isLoading = true
        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
