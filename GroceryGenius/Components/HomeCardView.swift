import SwiftUI

struct HomeCardView: View {
    var title: String
    var subtitle: String
    var icon: String

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.15))
                    .frame(width: 54, height: 54)
                    .shadow(color: AppColor.primary.opacity(0.2), radius: 6)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColor.primary)
                    .symbolEffect(.bounce, options: .nonRepeating)  // modern effect
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColor.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColor.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal)
        .padding(.top, 4)
        .transition(.scale.combined(with: .opacity))  // modern animate in/out
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: UUID())
    }
}
