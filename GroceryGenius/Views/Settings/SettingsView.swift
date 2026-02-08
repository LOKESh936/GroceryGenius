import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    

    @StateObject private var viewModel = SettingsViewModel()
    @State private var showSignOutConfirm = false

    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {


                        // MARK: - Profile
                        GGCard(cornerRadius: 22) {
                            NavigationLink {
                                EditProfileView()
                            } label: {
                                HStack(spacing: 12) {
                                    profileAvatar
                                        .frame(width: 44, height: 44)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName)
                                            .font(.headline)
                                            .foregroundStyle(AppColor.textPrimary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)

                                        if !email.isEmpty {
                                            Text(email)
                                                .font(.subheadline)
                                                .foregroundStyle(AppColor.textSecondary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                        }

                                        if let verified = Auth.auth().currentUser?.isEmailVerified,
                                           !verified {
                                            Text("Email not verified")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { Haptic.light() })
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                        // MARK: - Account & Security
                        sectionTitle("Account & Security")
                            .padding(.horizontal, 20)

                        GGCard(cornerRadius: 22) {
                            VStack(spacing: 0) {

                                navRow(
                                    title: "Change Password",
                                    icon: "key.fill",
                                    iconColor: .blue
                                ) {
                                    ChangePasswordView()
                                }


                                divider()

                                biometricsRow
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())

                                divider()

                                Button(role: .destructive) {
                                    Haptic.light()
                                    showSignOutConfirm = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(.blue)

                                        Text("Sign Out")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.red)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .confirmationDialog(
                                    "Are you sure you want to sign out?",
                                    isPresented: $showSignOutConfirm
                                ) {
                                    Button("Sign Out", role: .destructive) {
                                        do {
                                            try viewModel.signOut()
                                            Haptic.medium()
                                            onSignOut()
                                        } catch {
                                            viewModel.errorMessage = error.localizedDescription
                                        }
                                    }
                                    Button("Cancel", role: .cancel) { }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Support
                        sectionTitle("Support")
                            .padding(.horizontal, 20)

                        GGCard(cornerRadius: 22) {
                            Button {
                                Haptic.light()
                                contactSupport()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.blue)

                                    Text("Contact Support")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.blue)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Danger Zone
                        GGCard(cornerRadius: 22) {
                            NavigationLink {
                                DeleteAccountView(onSignOut: onSignOut)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.red)

                                    Text("Delete Account")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.red)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { Haptic.light() })
                        }
                        .padding(.horizontal, 20)

                        Color.clear.frame(height: 110) // space for custom tab bar
                    }
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .dynamicTypeSize(.xSmall ... .accessibility2)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadProfile()
                viewModel.refreshBiometricsCapability()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppColor.textSecondary)
    }

    private func divider() -> some View {
        Divider().opacity(0.15)
    }

    private func navRow<Destination: View>(
        title: String,
        icon: String,
        iconColor: Color,
        destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { Haptic.light() })
    }

    // MARK: - Biometrics Row

    private var biometricsRow: some View {
        HStack {
            Label("\(viewModel.biometricsLabel) Unlock",
                  systemImage: viewModel.biometricsIcon)

            Spacer()

            if viewModel.biometricsAvailable {
                Toggle("", isOn: Binding(
                    get: { viewModel.biometricsEnabled },
                    set: { newValue in
                        Task {
                            let ok = await viewModel.setBiometricsEnabledWithAuth(newValue)
                            if ok { Haptic.light() }
                        }
                    }
                ))
                .labelsHidden()
            } else {
                Text("Unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Data

    private var displayName: String {
        viewModel.profile?.displayName
        ?? Auth.auth().currentUser?.displayName
        ?? "Your Profile"
    }

    private var email: String {
        viewModel.profile?.email
        ?? Auth.auth().currentUser?.email
        ?? ""
    }

    private var profileAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            }
    }

    private func contactSupport() {
        let email = "support@grocerygenius.app"
        let subject = "GroceryGenius Support"
        let body = "Hi GroceryGenius Team,\n\nI need help with..."

        let encodedSubject =
        subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody =
        body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}
