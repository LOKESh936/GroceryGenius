import SwiftUI

struct AIIngredientRowView: View {

    let name: String
    let quantity: String

    @EnvironmentObject var groceryViewModel: GroceryViewModel

    private var isAdded: Bool {
        groceryViewModel.items.contains {
            $0.name.lowercased() == name.lowercased()
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Text("•")
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppFont.body(14))
                    .foregroundStyle(AppColor.textPrimary)

                if !quantity.isEmpty {
                    Text(quantity)
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer()

            Button {
                toggleItem()
            } label: {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isAdded ? AppColor.primary : AppColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private func toggleItem() {
        if isAdded {
            if let item = groceryViewModel.items.first(
                where: { $0.name.lowercased() == name.lowercased() }
            ) {
                groceryViewModel.delete(item)
                Haptic.light()
            }
        } else {
            groceryViewModel.addItem(name: name, quantity: quantity)
            Haptic.success()
        }
    }
}
