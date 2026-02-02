import SwiftUI
import LocalAuthentication

struct SwitchAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = AccountStore.shared

    let onSignOut: () -> Void

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    GGHeader(title: "Switch Account")

                    if store.accounts.isEmpty {
                        Text("No saved accounts yet.")
                            .foregroundStyle(AppColor.textSecondary)
                    } else {
                        GGCard(cornerRadius: 22) {
                            ForEach(store.accounts, id: \.id) { account in
                                accountRow(account)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            store.removeAccount(account)
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }

                    Button("Use Another Account") {
                        onSignOut()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        dismiss()
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Account Row

    private func accountRow(_ account: SavedAccount) -> some View {
        Button {
            switchAccount(account)
        } label: {
            VStack(alignment: .leading, spacing: 12) {

                // MARK: - Account identity
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {

                        // Primary label
                        Text(account.displayName ?? account.email)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        // Secondary label ONLY if different
                        if let name = account.displayName, name != account.email {
                            Text(account.email)
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    Spacer()

                    if account.id == store.selectedAccount?.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColor.primary)
                            .accessibilityLabel("Current account")
                    }
                }

                // MARK: - Face ID toggle (SINGLE label)
                Toggle(isOn: Binding(
                    get: { account.faceIDEnabled },
                    set: { enabled in
                        authenticateBiometrics {
                            store.toggleFaceID(for: account, enabled: enabled)
                        }
                    }
                )) {
                    Text("Use Face ID")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            print("Account:", account.email, account.id)
        }
    }


    // MARK: - Switch Logic

    private func switchAccount(_ account: SavedAccount) {
        store.select(account)

        NotificationCenter.default.post(
            name: .prefillAuthEmail,
            object: account.email
        )

        onSignOut()
        dismiss()
    }

    private func authenticateBiometrics(_ success: @escaping () -> Void) {
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return }

        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Enable Face ID for this account") { ok, _ in
            if ok { success() }
        }
    }
}
