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
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 24) {

                    SectionHeader(
                        title: "Rename List",
                        subtitle: "Update the name for this shopping history"
                    )

                    GGCard {
                        TextField("History title", text: $title)
                            .font(AppFont.body(16))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(12)
                            .background(AppColor.cardElevated)
                            .cornerRadius(12)
                            .submitLabel(.done)
                            .onSubmit { hideKeyboard() }
                    }

                    Spacer()
                }
                .padding(20)
            }
            // ✅ Tap anywhere to dismiss
            .dismissKeyboardOnTap()
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Haptic.medium()
                        Task {
                            await vm.rename(history, title: title)
                            dismiss()
                        }
                    }
                    .foregroundStyle(AppColor.primary)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
