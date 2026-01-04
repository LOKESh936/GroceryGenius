import SwiftUI

struct RootView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            switch authVM.authState {
            case .loading:
                LaunchLoadingView()

            case .authenticated:
                if let user = authVM.user, user.isEmailVerified {
                    ContentView()
                        .environmentObject(authVM)
                } else {
                    VerifyEmailView()
                        .environmentObject(authVM)
                }

            case .unauthenticated:
                AuthView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut, value: authVM.authState)
    }
}
