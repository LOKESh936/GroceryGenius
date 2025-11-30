import SwiftUI

struct GroceryRowView: View {
    let item: GroceryItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            // Check circle
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(AppColor.primary, lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColor.primary)
                    }
                }
            }
            .buttonStyle(.plain)

            // Name + quantity
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColor.primary)
                    .strikethrough(item.isCompleted, color: AppColor.primary)

                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.subheadline)
                        .foregroundColor(AppColor.primary.opacity(0.75))
                        .strikethrough(item.isCompleted, color: AppColor.primary.opacity(0.75))
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}
