import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    GGHeader(title: "Change Password")

                    GGCard(cornerRadius: 22) {
                        VStack(spacing: 14) {
                            secureField("Current Password", text: $currentPassword)
                            secureField("New Password", text: $newPassword)
                            secureField("Confirm Password", text: $confirmPassword)
                        }
                        .padding(16)
                    }

                    Button {
                        changePassword()
                    } label: {
                        Text(isWorking ? "Updating..." : "Update Password")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColor.primary,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .disabled(isWorking)

                    Button("Cancel") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer(minLength: 40)
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func changePassword() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isWorking = true

        Task {
            do {
                let credential = EmailAuthProvider.credential(
                    withEmail: email,
                    password: currentPassword
                )
                try await user.reauthenticate(with: credential)
                try await user.updatePassword(to: newPassword)

                Haptic.medium()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)

            SecureField(title, text: text)
                .padding(14)
                .background(AppColor.chromeSurface.opacity(0.6),
                            in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
