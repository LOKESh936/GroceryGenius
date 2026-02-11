import SwiftUI

struct SignUpView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showPasswordRules = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    private var pwScore: Int { PasswordRules.score(authVM.password) }
    private var pwLabel: String { PasswordRules.label(for: pwScore) }
    private var pwValid: Bool { PasswordRules.isValid(authVM.password) }

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    Spacer(minLength: 30)

                    // MARK: - Header
                    VStack(spacing: 16) {
                        
                        Image(systemName: "cart.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(AppColor.primary.opacity(0.15))
                            )

                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                    // MARK: - Form
                    VStack(spacing: 14) {

                        TextField("Email", text: $authVM.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColor.cardElevated)
                            )
                            .foregroundStyle(AppColor.textPrimary)

                        SecureInputField(
                            title: "Password",
                            text: $authVM.password
                        )
                        .focused($focusedField, equals: .password)
                        .onTapGesture {
                            showPasswordRules = true
                        }

                        // MARK: - Strength Meter
                        VStack(alignment: .leading, spacing: 8) {

                            HStack {
                                Text("Password strength: \(pwLabel)")
                                    .font(.footnote)
                                    .foregroundStyle(AppColor.textSecondary)

                                Spacer()

                                Button {
                                    showPasswordRules.toggle()
                                } label: {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(AppColor.primary)
                                }
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(AppColor.chromeSurface)
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(AppColor.primary)
                                        .frame(
                                            width: geo.size.width * CGFloat(pwScore) / 4.0,
                                            height: 8
                                        )
                                        .animation(.easeInOut(duration: 0.25), value: pwScore)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Create Account Button
                    Button {
                        focusedField = nil

                        guard pwValid else {
                            authVM.errorMessage = "Please choose a stronger password."
                            Haptic.light()
                            showPasswordRules = true
                            return
                        }

                        Task { await authVM.signUp() }
                    } label: {
                        ZStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            authVM.canSubmitSignup && pwValid
                            ? AppColor.primary
                            : AppColor.primary.opacity(0.45)
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: AppColor.chromeSurface,
                            radius: 10,
                            y: 4
                        )
                    }
                    .disabled(!authVM.canSubmitSignup || !pwValid || authVM.isLoading)
                    .padding(.horizontal, 24)

                    // MARK: - Error
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    // MARK: - Back to Login
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? Sign In")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColor.primary)
                    }

                    Spacer(minLength: 30)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 20)
            }
            
            if showPasswordRules {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPasswordRules = false
                    }

                PasswordRulesPopup {
                    showPasswordRules = false
                }
                .transition(.scale.combined(with: .opacity))
            }

        }
        .onTapGesture {
            focusedField = nil
        }
        
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Password Rules Sheet
private struct PasswordRulesPopup: View {

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            Text("Password Requirements")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                rule("At least 8 characters")
                rule("At least 1 uppercase letter (A–Z)")
                rule("At least 1 lowercase letter (a–z)")
                rule("At least 1 number or symbol")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColor.cardElevated)
            )

            Button("Got it") {
                onClose()
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(AppColor.primary)
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColor.background)
        )
        .shadow(radius: 20)
        .padding(.horizontal, 32)
    }

    private func rule(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(AppColor.primary)

            Text(text)
                .foregroundStyle(AppColor.textPrimary)
        }
        .font(.system(size: 15))
    }
}
