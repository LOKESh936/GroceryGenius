import SwiftUI

struct LaunchLoadingView: View {

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showBasket = false
    @State private var dropped = [false, false, false]
    @State private var glow = false

    var onFinished: (() -> Void)?

    // MARK: - Colors (dark-mode tuned)
    private var background: Color {
        scheme == .dark
        ? Color(red: 0.05, green: 0.06, blue: 0.07)
        : Color.white
    }

    private var shadowColor: Color {
        scheme == .dark ? .black.opacity(0.6) : .black.opacity(0.18)
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ZStack {

                // MARK: Basket
                Image("GroceryBasketBase")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 155)
                    .opacity(showBasket ? 1 : 0)
                    .scaleEffect(showBasket ? 1 : 0.95)
                    .shadow(
                        color: shadowColor,
                        radius: 22,
                        y: 18
                    )
                    .animation(.easeOut(duration: 0.6), value: showBasket)

                // MARK: Falling groceries
                ZStack {
                    grocery(
                        image: "GroceryItemBottle",
                        index: 0,
                        x: -28,
                        rotation: -6,
                        depth: 10
                    )

                    grocery(
                        image: "GroceryItemApple",
                        index: 1,
                        x: 2,
                        rotation: 4,
                        depth: 14
                    )

                    grocery(
                        image: "GroceryItemCarrot",
                        index: 2,
                        x: 30,
                        rotation: -8,
                        depth: 8
                    )
                }
                .offset(y: -46)

                // MARK: Activation glow
                Circle()
                    .stroke(Color.green.opacity(scheme == .dark ? 0.25 : 0.35), lineWidth: 2)
                    .frame(width: 190, height: 190)
                    .scaleEffect(glow ? 1.12 : 0.85)
                    .opacity(glow ? 1 : 0)
                    .animation(.easeInOut(duration: 0.55), value: glow)
            }
        }
        .onAppear { start() }
    }

    // MARK: - Grocery physics
    private func grocery(
        image: String,
        index: Int,
        x: CGFloat,
        rotation: Double,
        depth: CGFloat
    ) -> some View {

        let landed = dropped[index]

        return Image(image)
            .resizable()
            .scaledToFit()
            .frame(width: 36)
            .rotationEffect(.degrees(landed ? rotation : rotation * 3))
            .offset(
                x: x,
                y: landed ? 0 : -190
            )
            .scaleEffect(landed ? 1 : 1.08)
            .opacity(landed ? 1 : 0)
            .shadow(
                color: shadowColor,
                radius: landed ? depth : 0,
                y: landed ? depth : 0
            )
            .animation(
                reduceMotion
                ? .easeInOut(duration: 0.3)
                : .interpolatingSpring(
                    mass: 0.55,        // weight
                    stiffness: 160,    // snap
                    damping: 12,       // bounce
                    initialVelocity: 0
                ),
                value: landed
            )
    }

    // MARK: - Timeline
    private func start() {

        showBasket = true

        guard !reduceMotion else {
            dropped = [true, true, true]
            glow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onFinished?()
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            dropped[0] = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            dropped[1] = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            dropped[2] = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            glow = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onFinished?()
        }
    }
}
