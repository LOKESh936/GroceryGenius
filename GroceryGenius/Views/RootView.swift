import SwiftUI

struct RootView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var recipesVM: RecipesViewModel

    var body: some View {
        ZStack {
            switch authVM.authState {

            case .loading:
                LaunchLoadingView()

            case .authenticated:
                if let user = authVM.user, user.isEmailVerified {
                    ContentView()
                        .environmentObject(authVM)
                        .onAppear {
                            // START LISTENING ON LOGIN
                            recipesVM.startListening()
                        }
                } else {
                    VerifyEmailView()
                        .environmentObject(authVM)
                }

            case .unauthenticated:
                AuthView()
                    .environmentObject(authVM)
                    .onAppear {
                        // STOP LISTENING ON LOGOUT
                        recipesVM.stopListening()
                    }
            }
        }
        .animation(.easeInOut, value: authVM.authState)
    }
}
