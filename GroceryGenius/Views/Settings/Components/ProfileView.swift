import SwiftUI
import FirebaseAuth

struct ProfileView: View {

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {

            // MARK: - Profile Info
            Section {
                VStack(spacing: 12) {

                    profileImage

                    Text(viewModel.profile?.displayName ?? "—")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(viewModel.user?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let verified = viewModel.user?.isEmailVerified, !verified {
                        Text("Email not verified")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Email verified")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // MARK: - Actions
            Section {
                NavigationLink("Edit Profile") {
                    EditProfileView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Profile Image

    private var profileImage: some View {
        Group {
            if let url = viewModel.user?.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderAvatar
                    default:
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            }
    }
}
