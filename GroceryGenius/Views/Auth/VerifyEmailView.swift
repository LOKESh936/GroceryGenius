import SwiftUI
import FirebaseAuth

struct VerifyEmailView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSending = false
    @State private var message: String?

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 28) {

                Spacer()

                // MARK: - Icon & Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48))
                        .foregroundColor(AppColor.primary)

                    Text("Verify your email")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColor.textPrimary)

                    Text("""
We’ve sent a verification link to your email address.
Please verify your email to continue using GroceryGenius.
""")
                        .font(.system(size: 15))
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                // MARK: - Actions
                VStack(spacing: 14) {

                    // Refresh status
                    Button {
                        Task {
                            await refreshVerificationStatus()
                        }
                    } label: {
                        Text("I’ve verified my email")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }

                    // Resend email
                    Button {
                        Task {
                            await resendVerification()
                        }
                    } label: {
                        Text(isSending ? "Sending…" : "Resend verification email")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColor.primary)
                    }
                    .disabled(isSending)

                    // Sign out
                    Button {
                        authVM.signOut()
                    } label: {
                        Text("Sign out")
                            .font(.system(size: 15))
                            .foregroundColor(.red.opacity(0.85))
                    }
                }
                .padding(.horizontal, 24)

                // MARK: - Feedback
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(
                            message.lowercased().contains("sent")
                            ? .green
                            : .red
                        )
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    private func refreshVerificationStatus() async {
        guard let user = Auth.auth().currentUser else { return }

        do {
            try await user.reload()
            if user.isEmailVerified {
                Haptic.success()
            } else {
                message = "Email not verified yet. Please check your inbox."
                Haptic.light()
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func resendVerification() async {
        guard let user = Auth.auth().currentUser else { return }

        isSending = true
        do {
            try await user.sendEmailVerification()
            message = "Verification email sent."
            Haptic.success()
        } catch {
            message = error.localizedDescription
        }
        isSending = false
    }
}
