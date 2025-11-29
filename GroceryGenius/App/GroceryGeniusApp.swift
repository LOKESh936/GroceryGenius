import SwiftUI

@main
struct GroceryGeniusApp: App {
    // Shared grocery list for the whole app
    @StateObject private var groceryViewModel = GroceryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groceryViewModel) // inject into all child views
        }
    }
}
