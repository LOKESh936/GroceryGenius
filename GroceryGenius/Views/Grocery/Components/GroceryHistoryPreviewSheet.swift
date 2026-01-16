import SwiftUI

struct GroceryHistoryPreviewSheet: View {

    let history: GroceryHistory
    @EnvironmentObject var groceryVM: GroceryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 16) {

                    SectionHeader(
                        title: history.title,
                        subtitle: "\(history.items.count) items"
                    )

                    List {
                        ForEach(history.items) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.quantity)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    Button {
                        Haptic.medium()
                        groceryVM.clearAll()
                        history.items.forEach {
                            groceryVM.addItem(name: $0.name, quantity: $0.quantity)
                        }
                        dismiss()
                    } label: {
                        Text("Restore This List")
                            .font(AppFont.subtitle(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
    }
}
