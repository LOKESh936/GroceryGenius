import SwiftUI
import Firebase

@main
struct GroceryGeniusApp: App {

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var groceryViewModel: GroceryViewModel
    @StateObject private var aiViewModel: AIViewModel

    init() {
        FirebaseApp.configure()

        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        _groceryViewModel = StateObject(wrappedValue: GroceryViewModel())
        _aiViewModel = StateObject(wrappedValue: AIViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(groceryViewModel)
                .environmentObject(aiViewModel)
        }
    }
}
