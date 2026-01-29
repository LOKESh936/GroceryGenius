import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {

            Button(role: .destructive) {
                authVM.signOut()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }
}
#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}

