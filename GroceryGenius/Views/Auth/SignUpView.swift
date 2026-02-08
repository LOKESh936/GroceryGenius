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
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding()
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
        }
        .sheet(isPresented: $showPasswordRules) {
            PasswordRulesSheet()
                .presentationDetents([.medium])
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Password Rules Sheet
private struct PasswordRulesSheet: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Password Requirements")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            rule("At least 8 characters")
            rule("At least 1 uppercase letter (A–Z)")
            rule("At least 1 lowercase letter (a–z)")
            rule("At least 1 number or symbol")

            Spacer()
        }
        .padding(20)
        .background(AppColor.background)
    }

    private func rule(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
            Text(text)
        }
        .foregroundStyle(.primary)
    }
}
