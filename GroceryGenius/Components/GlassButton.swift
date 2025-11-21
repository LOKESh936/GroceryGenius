import SwiftUI

struct GlassButton: View {
    var title: String? = nil      // title is OPTIONAL
    var icon: String              // icon is REQUIRED
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: title == nil ? 0 : 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))

                if let title {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, title == nil ? 10 : 16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }
}
