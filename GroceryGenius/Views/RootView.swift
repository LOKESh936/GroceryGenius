import SwiftUI
import FirebaseAuth

struct RootView: View {

    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.user != nil {
                // 🔹 User is logged in -> show main app
                ContentView()
                    .environmentObject(authVM) // so you can call signOut() in Settings later
            } else {
                // 🔸 Not logged in -> show auth screen
                AuthView()
                    .environmentObject(authVM)
            }
        }
    }
}
