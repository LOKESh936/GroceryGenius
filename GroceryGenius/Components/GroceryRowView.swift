import SwiftUI

struct GroceryRowView: View {
    let item: GroceryItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(AppColor.primary.opacity(0.9), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .strikethrough(item.isCompleted, color: AppColor.primary.opacity(0.8))
                    .opacity(item.isCompleted ? 0.75 : 1)

                if !item.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.quantity)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.primary.opacity(0.7))
                        .strikethrough(item.isCompleted, color: AppColor.primary.opacity(0.55))
                        .opacity(item.isCompleted ? 0.7 : 1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
        )
    }
}
