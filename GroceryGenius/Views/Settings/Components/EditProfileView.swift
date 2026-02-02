import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    GGHeader(title: "Edit Profile")

                    GGCard(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Display Name")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)

                            TextField("Your name", text: $displayName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(AppColor.chromeSurface.opacity(0.6),
                                            in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(16)
                    }

                    Button {
                        save()
                    } label: {
                        Text(isSaving ? "Saving..." : "Save Changes")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColor.primary,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .disabled(isSaving || displayName.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)

                    Spacer(minLength: 40)
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            displayName = Auth.auth().currentUser?.displayName ?? ""
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

    private func save() {
        guard let user = Auth.auth().currentUser else { return }
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true

        Task {
            do {
                let request = user.createProfileChangeRequest()
                request.displayName = trimmed
                try await request.commitChanges()

                try await Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .setData([
                        "displayName": trimmed,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)

                Haptic.medium()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
