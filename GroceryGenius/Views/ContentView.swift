import SwiftUI

struct ContentView: View {

    @EnvironmentObject var aiVM: AIViewModel
    @EnvironmentObject var groceryVM: GroceryViewModel

    @State private var selectedTab: Tab = .home
    @Namespace private var tabNamespace

    @State private var showGroceryHistorySheet = false
    @StateObject private var groceryHistoryVM = GroceryHistoryViewModel()

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
            }
        }
        // ✅ FIX: tab bar is now anchored to the bottom safe area (rotation-safe)
        .safeAreaInset(edge: .bottom) {
            customTabBar
                .padding(.bottom, 8)
        }
        // ✅ Keep layout stable when keyboard appears (tab bar won’t jump)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .openGroceryHistory)) { _ in
            showGroceryHistorySheet = true
        }
        .sheet(isPresented: $showGroceryHistorySheet) {
            GroceryHistoryView()
                .environmentObject(groceryHistoryVM)
                .environmentObject(groceryVM)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text("GroceryGenius")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColor.primary)

                Group {
                    if selectedTab == .aiMeals {
                        Text(aiVM.activeConversationTitle)
                            .id(aiVM.activeConversationTitle)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.22), value: aiVM.activeConversationTitle)
                    } else {
                        Text(selectedTab.title)
                            .id(selectedTab.title)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.22), value: selectedTab)
                    }
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 10) {

                // HISTORY BUTTON — ONLY FOR GROCERY
                if selectedTab == .grocery {
                    Button {
                        NotificationCenter.default.post(name: .openGroceryHistory, object: nil)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 36, height: 36)
                            // ✅ Dark mode safe surface (avoid Color.white.opacity)
                            .background(Circle().fill(AppColor.chromeSurface))
                    }
                    .accessibilityLabel("Grocery History")
                }

                // AI header controls
                if selectedTab == .aiMeals {
                    Button {
                        NotificationCenter.default.post(name: .openAIChats, object: nil)
                    } label: {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColor.chromeSurface))
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColor.primary.opacity(0.85))
                            .frame(width: 8, height: 8)

                        Text("AI powered")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColor.chromeSurface.opacity(0.85))
                    )
                }
            }
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
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        // ✅ Important: full-width safe for rotation
        .frame(maxWidth: .infinity)
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
            .foregroundStyle(isSelected ? Color.white : AppColor.primary.opacity(0.85))
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
                            .matchedGeometryEffect(id: "tabBackground", in: tabNamespace)
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
