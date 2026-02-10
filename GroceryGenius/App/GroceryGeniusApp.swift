import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct GroceryGeniusApp: App {

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var groceryViewModel: GroceryViewModel
    @StateObject private var aiViewModel: AIViewModel
    @StateObject private var recipesVM = RecipesViewModel()
   
    @StateObject private var recipesViewModel: RecipesViewModel
    
    private var authListener: AuthStateDidChangeListenerHandle?


    init() {
        FirebaseApp.configure()

        // ✅ Offline-first persistence (robust / correct approach)
        let db = Firestore.firestore()
        let settings = db.settings
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings

        
        authListener = Auth.auth().addStateDidChangeListener { _, user in
            guard user != nil else { return }
            AccountStore.shared.saveCurrentUser()
        }
        
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        _groceryViewModel = StateObject(wrappedValue: GroceryViewModel())
        _aiViewModel = StateObject(wrappedValue: AIViewModel())
        _recipesViewModel = StateObject(wrappedValue: RecipesViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(groceryViewModel)
                .environmentObject(aiViewModel)
                .environmentObject(recipesViewModel)
                .environmentObject(recipesVM)
                .tint(AppColor.accent)
        }
    }
}
