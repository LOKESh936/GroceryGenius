import SwiftUI

struct ContentView: View {

    @State private var selectedTab: Tab = .home
    @Namespace private var tabNamespace   // ✅ FIX

    enum Tab: String, CaseIterable, Identifiable {
        case home
        case grocery
        case aiMeals
        case recipes
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home:     return "Home"
            case .grocery:  return "Groceries"
            case .aiMeals:  return "AI Meals"
            case .recipes:  return "Recipes"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .home:     return "house.fill"
            case .grocery:  return "cart.fill"
            case .aiMeals:  return "sparkles"
            case .recipes:  return "book.pages.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ZStack {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .grocery:
                        GroceryListView()
                    case .aiMeals:
                        AIFoodView()
                    case .recipes:
                        RecipesView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.easeInOut(duration: 0.22), value: selectedTab)

                customTabBar
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GroceryGenius")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColor.primary)

                Text(selectedTab.title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColor.primary.opacity(0.8))
                            .frame(width: 8, height: 8)
                        Text("AI powered")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                )
                .frame(height: 30)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 10) {
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = tab == selectedTab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .semibold))

                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .foregroundStyle(isSelected ? Color.white : AppColor.primary.opacity(0.8))
            .padding(.horizontal, isSelected ? 14 : 10)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.primary, AppColor.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .matchedGeometryEffect(
                                id: "tabBackground",
                                in: tabNamespace        // ✅ FIX
                            )
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
