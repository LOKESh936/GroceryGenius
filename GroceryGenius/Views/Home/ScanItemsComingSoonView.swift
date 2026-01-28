import SwiftUI

struct ScanItemsComingSoonView: View {

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 20) {

                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColor.primary)

                Text("Scan Items")
                    .font(AppFont.title(22))

                Text("""
Soon you’ll be able to scan food items using your camera and instantly see total calories and nutrition details.
""")
                .font(AppFont.body(14))
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

                Spacer()

                Text("Coming Soon 🚀")
                    .font(AppFont.caption(12))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .navigationTitle("Scan Items")
        .navigationBarTitleDisplayMode(.inline)
    }
}
