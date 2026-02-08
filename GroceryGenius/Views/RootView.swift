import SwiftUI

struct RootView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var recipesVM: RecipesViewModel

    @State private var showLaunchAnimation = true

    var body: some View {
        ZStack {

            // MARK: - Main App Routing (always alive underneath)
            mainContent
                .opacity(showLaunchAnimation ? 0 : 1)

            // MARK: - One-time Launch Animation
            if showLaunchAnimation {
                LaunchLoadingView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showLaunchAnimation = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authVM.authState)
    }

    // MARK: - App Router
    @ViewBuilder
    private var mainContent: some View {
        switch authVM.authState {

        case .loading:
            // Keep neutral while Firebase resolves
            Color.clear

        case .authenticated:
            if let user = authVM.user, user.isEmailVerified {
                ContentView()
                    .environmentObject(authVM)
                    .onAppear {
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
                    recipesVM.stopListening()
                }
        }
    }
}
