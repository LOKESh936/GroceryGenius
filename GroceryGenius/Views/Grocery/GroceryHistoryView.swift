import SwiftUI

struct GroceryHistoryView: View {

    @EnvironmentObject var vm: GroceryHistoryViewModel
    @EnvironmentObject var groceryVM: GroceryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var renaming: GroceryHistory?

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.history) { history in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(history.title)
                            .font(.system(size: 16, weight: .semibold))

                        Text(history.completedAt.formatted())
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .swipeActions {
                        Button {
                            renaming = history
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            Task { await vm.delete(history) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        history.items.forEach {
                            groceryVM.addItem(name: $0.name, quantity: $0.quantity)
                        }
                        dismiss()
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                Task { await vm.load() }
            }
            .sheet(item: $renaming) { history in
                RenameHistorySheet(history: history)
            }
        }
    }
}
