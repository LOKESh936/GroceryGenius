import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TabView {
                
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                RecipesView()
                    .tabItem {
                        Label("Recipes", systemImage: "book")
                    }
                
                AIFoodView()
                    .tabItem {
                        Label("AI Meals", systemImage: "sparkles")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .accentColor(AppColor.accent)
        }
    }
}

#Preview {
    ContentView()
}
