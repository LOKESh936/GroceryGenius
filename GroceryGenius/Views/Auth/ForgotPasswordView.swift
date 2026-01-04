import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    Spacer(minLength: 40)

                    // MARK: - Header
                    VStack(spacing: 14) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 44))
                            .foregroundColor(AppColor.primary)

                        Text("Reset Password")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColor.textPrimary)

                        Text("Enter your email and we’ll send you a reset link.")
                            .font(.system(size: 15))
                            .foregroundColor(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // MARK: - Email Field
                    TextField("Email", text: $authVM.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($emailFocused)
                        .submitLabel(.done)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 24)

                    // MARK: - Send Reset Link
                    Button {
                        emailFocused = false
                        Task {
                            await authVM.resetPassword()
                        }
                    } label: {
                        ZStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            authVM.email.isEmpty
                            ? AppColor.primary.opacity(0.45)
                            : AppColor.primary
                        )
                        .cornerRadius(16)
                    }
                    .disabled(authVM.email.isEmpty || authVM.isLoading)
                    .padding(.horizontal, 24)

                    // MARK: - Feedback Message
                    if let message = authVM.errorMessage {
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

                    // MARK: - Back to Login
                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Sign In")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColor.primary)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    emailFocused = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
