import SwiftUI

struct HomeView: View {

    @State private var showHero = false
    @State private var showGrid = false

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    HomeHeroView()
                        .opacity(showHero ? 1 : 0)
                        .offset(y: showHero ? 0 : 18)
                        .animation(
                            .spring(response: 0.7, dampingFraction: 0.85),
                            value: showHero
                        )

                    SectionHeader(
                        title: "Quick actions",
                        subtitle: "Jump back into what you do most"
                    )
                    .padding(.horizontal, 20)

                    HomeQuickActionGrid()
                        .opacity(showGrid ? 1 : 0)
                        .offset(y: showGrid ? 0 : 24)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.9)
                                .delay(0.1),
                            value: showGrid
                        )
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            showHero = true
            showGrid = true
        }
    }
}
