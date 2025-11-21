import SwiftUI
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    
                    Text("Welcome back 👋")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppColor.primary)
                    
                    Text("What would you like to do today?")
                        .foregroundStyle(AppColor.secondary)
                    
                    NavigationLink(destination: GroceryListView()) {
                        HomeCardView(
                            title: "Manage Grocery List",
                            subtitle: "Add, edit, delete items",
                            icon: "cart"
                        )
                    }
                    
                    HomeCardView(
                        title: "AI Meal Planner",
                        subtitle: "Smart meals based on your groceries",
                        icon: "sparkles"
                    )
                    
                    HomeCardView(
                        title: "Browse Recipes",
                        subtitle: "Find trending recipes online",
                        icon: "book"
                    )
                    
                    HomeCardView(
                        title: "Scan Food Items",
                        subtitle: "Barcode or camera scan",
                        icon: "camera"
                    )
                }
                .padding()
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Grocery Genius")
        }
    }
}

#Preview {
    HomeView()
}
