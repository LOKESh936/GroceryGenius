import Foundation
import LocalAuthentication

@MainActor
final class BiometricAuth: ObservableObject {

    @Published var isAvailable: Bool = false
    @Published var biometryType: LABiometryType = .none

    init() {
        refreshAvailability()
    }

    func refreshAvailability() {
        let context = LAContext()
        var error: NSError?

        let can = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        isAvailable = can
        biometryType = context.biometryType
    }

    func authenticate(reason: String = "Unlock GroceryGenius") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            return false
        }
    }

    var buttonTitle: String {
        switch biometryType {
        case .faceID: return "Continue with Face ID"
        case .touchID: return "Continue with Touch ID"
        default: return "Continue"
        }
    }

    var buttonIcon: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }
}
