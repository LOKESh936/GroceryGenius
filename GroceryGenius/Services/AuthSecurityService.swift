import Foundation
import FirebaseAuth

#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

@MainActor
final class AuthSecurityService {

    static let shared = AuthSecurityService()
    private init() {}

    /// Re-auth gate (email/password)
    func reauthenticate(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    /// Logout this device
    func signOut() throws {
        try Auth.auth().signOut()
    }

    /// Logout all devices (requires backend support)
    func signOutAllDevices() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        #if canImport(FirebaseFunctions)
        let functions = Functions.functions()
        let callable = functions.httpsCallable("revokeTokens") // you will create this
        _ = try await callable.call(["uid": uid])
        #else
        throw NSError(
            domain: "Auth",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey:
                "Logout all devices requires Firebase Functions. Add FirebaseFunctions SDK and a callable 'revokeTokens' function."
            ]
        )
        #endif
    }
}
