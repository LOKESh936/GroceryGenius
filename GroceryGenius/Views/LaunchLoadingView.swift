import SwiftUI

struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColor.primary)
        }
    }
}
