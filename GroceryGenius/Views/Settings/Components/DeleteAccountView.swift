import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DeleteAccountView: View {

    @Environment(\.dismiss) private var dismiss
    let onSignOut: () -> Void

    @State private var confirmText = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    GGHeader(title: "Delete Account", isDestructive: true)

                    Text("This action permanently deletes your account and cannot be undone.")
                        .font(.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    GGCard(cornerRadius: 22) {
                        VStack(spacing: 14) {

                            Text("Type DELETE to confirm")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)

                            TextField("DELETE", text: $confirmText)
                                .textInputAutocapitalization(.characters)
                                .padding(14)
                                .background(AppColor.chromeSurface.opacity(0.6),
                                            in: RoundedRectangle(cornerRadius: 14))

                            SecureField("Password", text: $password)
                                .padding(14)
                                .background(AppColor.chromeSurface.opacity(0.6),
                                            in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(16)
                    }

                    Button {
                        deleteAccount()
                    } label: {
                        Text(isWorking ? "Deleting..." : "Delete Account")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .disabled(confirmText != "DELETE" || password.isEmpty || isWorking)

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

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        isWorking = true

        Task {
            do {
                let credential = EmailAuthProvider.credential(
                    withEmail: email,
                    password: password
                )
                try await user.reauthenticate(with: credential)

                try await Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .delete()

                try await user.delete()

                onSignOut()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }
}
