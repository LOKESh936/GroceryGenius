import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var user: User?
    @Published private(set) var profile: UserProfile?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Biometrics (Single Source of Truth)

    @Published var biometricsEnabled: Bool = false
    @Published private(set) var biometricsAvailable: Bool = false

    // MARK: - Init

    init() {
        self.user = Auth.auth().currentUser
        refreshBiometricsCapability()
        biometricsEnabled = UserDefaults.standard.bool(forKey: "gg_biometrics_enabled")
    }

    // MARK: - User Info

    func loadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let snap = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            if snap.exists {
                self.profile = try snap.data(as: UserProfile.self)
            } else {
                self.profile = nil
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Biometrics Capability

    func refreshBiometricsCapability() {
        let ctx = LAContext()
        var err: NSError?

        biometricsAvailable = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &err
        )

        if !biometricsAvailable {
            biometricsEnabled = false
            UserDefaults.standard.set(false, forKey: "gg_biometrics_enabled")
        }
    }

    var biometricsLabel: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    var biometricsIcon: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch ctx.biometryType {
        case .touchID: return "touchid"
        default: return "faceid"
        }
    }

    /// Requires real FaceID / TouchID when enabling
    func setBiometricsEnabledWithAuth(_ enabled: Bool) async -> Bool {
        if !enabled {
            biometricsEnabled = false
            UserDefaults.standard.set(false, forKey: "gg_biometrics_enabled")
            return true
        }

        let success = await authenticateBiometrics(
            reason: "Enable biometrics unlock for GroceryGenius"
        )

        if success {
            biometricsEnabled = true
            UserDefaults.standard.set(true, forKey: "gg_biometrics_enabled")
        }

        return success
    }

    private func authenticateBiometrics(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let ctx = LAContext()
            ctx.localizedCancelTitle = "Cancel"

            var err: NSError?
            guard ctx.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &err
            ) else {
                continuation.resume(returning: false)
                return
            }

            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }
}
