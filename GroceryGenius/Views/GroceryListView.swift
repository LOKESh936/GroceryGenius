import SwiftUI

struct GroceryListView: View {
    @StateObject var viewModel = GroceryViewModel()
    @State private var name = ""
    @State private var quantity = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // MARK: - Input section
                HStack(spacing: 12) {
                    TextField("Item name", text: $name)
                        .padding()
                        .background(AppColor.background.opacity(0.8))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    
                    TextField("Qty", text: $quantity)
                        .padding()
                        .background(AppColor.background.opacity(0.8))
                        .cornerRadius(12)
                        .frame(width: 80)
                    
                    Button {
                        if !name.isEmpty {
                            viewModel.addItem(name: name, quantity: quantity)
                            name = ""
                            quantity = ""
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(14)
                            .background(AppColor.accent)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Divider()
                    .opacity(0.5)
                
                // MARK: - Grocery List
                List {
                    ForEach(viewModel.items) { item in
                        GroceryRowView(item: item, viewModel: viewModel)
                            .listRowSeparator(.hidden)
                            .listRowBackground(AppColor.background.opacity(0.3))
                    }
                    .onDelete(perform: viewModel.deleteItem)
                }
                .scrollContentBackground(.hidden)
                .background(AppColor.background)
                
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Grocery List")
        }
    }
}
