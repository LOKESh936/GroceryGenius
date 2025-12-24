import SwiftUI

struct HomeQuickActionGrid: View {

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {

            NavigationLink {
                GroceryListView()
            } label: {
                HomeQuickActionTile(
                    title: "Groceries",
                    subtitle: "Manage items",
                    icon: "cart.fill",
                    color: AppColor.primary
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                AIFoodView()
            } label: {
                HomeQuickActionTile(
                    title: "AI Meals",
                    subtitle: "Smart plans",
                    icon: "sparkles",
                    color: AppColor.accent,
                    badge: "AI"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RecipesView()
            } label: {
                HomeQuickActionTile(
                    title: "Recipes",
                    subtitle: "Discover ideas",
                    icon: "book.pages.fill",
                    color: AppColor.secondary,
                    badge: "NEW"
                )
            }
            .buttonStyle(.plain)

            HomeQuickActionTile(
                title: "Scan Items",
                subtitle: "Coming soon",
                icon: "camera.fill",
                color: AppColor.secondary.opacity(0.7),
                isDisabled: true
            )
        }
        .padding(.horizontal, 20)
    }
}
