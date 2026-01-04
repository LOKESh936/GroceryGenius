import SwiftUI

struct AuthView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @StateObject private var bio = BiometricAuth()

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {

                        Spacer(minLength: 40)

                        // MARK: - Logo
                        VStack(spacing: 16) {
                            Image("AppIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(AppColor.primary.opacity(0.15))
                                )

                            Text("GroceryGenius")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppColor.textPrimary)

                            Text("Welcome back")
                                .font(.system(size: 15))
                                .foregroundColor(AppColor.textSecondary)
                        }

                        // MARK: - Form
                        VStack(spacing: 14) {

                            TextField("Email", text: $authVM.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)

                            SecureInputField(
                                title: "Password",
                                text: $authVM.password
                            )
                            .focused($focusedField, equals: .password)

                            // Forgot password
                            Button {
                                focusedField = nil
                                showForgotPassword = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColor.primary.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: - Sign In Button
                        Button {
                            focusedField = nil
                            Task {
                                await authVM.signIn()
                            }
                        } label: {
                            ZStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                authVM.canSubmitLogin
                                ? AppColor.primary
                                : AppColor.primary.opacity(0.5)
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        }
                        .disabled(!authVM.canSubmitLogin || authVM.isLoading)
                        .padding(.horizontal, 24)

                        // MARK: - Biometric Login
                        if bio.isAvailable {
                            Button {
                                guard !authVM.isLoading else { return }
                                Task {
                                    let ok = await bio.authenticate()
                                    ok ? Haptic.success() : Haptic.light()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: bio.buttonIcon)
                                    Text(bio.buttonTitle)
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColor.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColor.primary.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .disabled(authVM.isLoading)
                            .padding(.horizontal, 24)
                            .onAppear { bio.refreshAvailability() }
                        }

                        // MARK: - Error Message
                        if let error = authVM.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                        }

                        // MARK: - Navigation to Sign Up
                        Button {
                            showSignUp = true
                        } label: {
                            Text("New here? Create an account")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColor.primary)
                        }
                        .padding(.top, 6)

                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            // MARK: - Navigation
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authVM)
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authVM)
            }
        }
    }
}
