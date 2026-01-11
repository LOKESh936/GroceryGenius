import SwiftUI

struct RenameHistorySheet: View {
    let history: GroceryHistory
    @EnvironmentObject var vm: GroceryHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(history: GroceryHistory) {
        self.history = history
        _title = State(initialValue: history.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
            }
            .navigationTitle("Rename")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await vm.rename(history, title: title)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
