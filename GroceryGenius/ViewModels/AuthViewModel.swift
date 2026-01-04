import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Auth State (Source of Truth)

    enum AuthState: Equatable {
        case loading
        case authenticated
        case unauthenticated
    }

    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var user: User?

    // MARK: - UI State

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?

    // MARK: - Init

    init() {
        listenToAuthChanges()
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Firebase Auth Listener

    private func listenToAuthChanges() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.user = user

            if let user {
                // Optional: enforce email verification
                if user.isEmailVerified {
                    self.authState = .authenticated
                } else {
                    self.authState = .unauthenticated
                }
            } else {
                self.authState = .unauthenticated
            }
        }
    }

    // MARK: - Computed Properties

    var canSubmitLogin: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }

    var canSubmitSignup: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8 &&
        !isLoading
    }

    // MARK: - Actions

    func signIn() async {
        errorMessage = nil
        isLoading = true

        do {
            let result = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )

            // Refresh user state
            try await result.user.reload()

            if !result.user.isEmailVerified {
                errorMessage = "Please verify your email before signing in."
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp() async {
        errorMessage = nil
        isLoading = true

        do {
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )

            // 🔑 VERY IMPORTANT: send verification email
            try await result.user.sendEmailVerification()

            errorMessage = "Verification email sent. Please check your inbox."

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resetPassword() async {
        guard !email.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "Password reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func clearInputs() {
        email = ""
        password = ""
        errorMessage = nil
    }
}
