import SwiftUI

struct GroceryRowView: View {
    let item: GroceryItem
    @ObservedObject var viewModel: GroceryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            
            Button {
                viewModel.toggleItem(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(item.isCompleted ? AppColor.primary : AppColor.secondary)
                    .symbolEffect(.bounce, value: item.isCompleted)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : AppColor.primary)
                
                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundColor(AppColor.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
