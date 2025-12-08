import SwiftUI

struct AuthView: View {

    @StateObject var authVM = AuthViewModel()
    @State private var isSignUpMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Text("GroceryGenius")
                    .font(.largeTitle.bold())

                Text(isSignUpMode ? "Create an account" : "Welcome back")
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    TextField("Email", text: $authVM.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    SecureField("Password", text: $authVM.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        if isSignUpMode {
                            await authVM.signUp()
                        } else {
                            await authVM.signIn()
                        }
                    }
                } label: {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                        } else {
                            Text(isSignUpMode ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(authVM.email.isEmpty || authVM.password.count < 6)

                Button {
                    withAnimation {
                        isSignUpMode.toggle()
                    }
                } label: {
                    Text(isSignUpMode
                         ? "Already have an account? Sign in"
                         : "New here? Create an account")
                        .font(.footnote)
                }

                Spacer()
            }
            .padding()
        }
    }
}
