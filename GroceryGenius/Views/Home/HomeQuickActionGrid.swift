import SwiftUI

struct HomeQuickActionGrid: View {

    @Binding var selectedTab: ContentView.Tab
    @State private var showComingSoon = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {

            HomeQuickActionTile(
                title: "Groceries",
                subtitle: "Manage items",
                icon: "cart.fill",
                color: AppColor.primary
            ) {
                selectedTab = .grocery
            }

            HomeQuickActionTile(
                title: "AI Meals",
                subtitle: "Smart plans",
                icon: "sparkles",
                color: AppColor.accent
            ) {
                selectedTab = .aiMeals
            }

            HomeQuickActionTile(
                title: "Recipes",
                subtitle: "Discover ideas",
                icon: "book.pages.fill",
                color: AppColor.secondary
            ) {
                selectedTab = .recipes
            }

            HomeQuickActionTile(
                title: "Scan Items",
                subtitle: "Coming soon",
                icon: "camera.fill",
                color: AppColor.secondary.opacity(0.7)
            ) {
                showComingSoon = true
            }
        }
        .padding(.horizontal, 20)
        .alert("Coming soon 🚧", isPresented: $showComingSoon) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Soon you’ll be able to scan food items using your camera and instantly see total calories and nutrition details.")
        }
    }
}
