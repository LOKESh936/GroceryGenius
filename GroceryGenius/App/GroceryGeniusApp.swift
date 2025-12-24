import SwiftUI
import Firebase

@main
struct GroceryGeniusApp: App {

    @StateObject private var groceryViewModel = GroceryViewModel()
    @StateObject private var aiViewModel = AIViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groceryViewModel)
                .environmentObject(aiViewModel)
        }
    }
}
