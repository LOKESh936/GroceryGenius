import SwiftUI

struct GroceryHistoryPreviewSheet: View {

    let history: GroceryHistory
    @EnvironmentObject var groceryVM: GroceryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {

                    // MARK: - Header
                    VStack(spacing: 6) {
                        Text(history.title)
                            .font(AppFont.title(22))
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("\(history.items.count) item\(history.items.count == 1 ? "" : "s")")
                            .font(AppFont.caption(13))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.top, 8)

                    // MARK: - Items Preview
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(history.items) { item in
                                GGCard(cornerRadius: 16) {
                                    HStack(spacing: 12) {

                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(AppColor.primary.opacity(0.85))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(AppFont.body(15))
                                                .foregroundStyle(AppColor.textPrimary)

                                            if !item.quantity.isEmpty {
                                                Text(item.quantity)
                                                    .font(AppFont.caption(12))
                                                    .foregroundStyle(AppColor.textSecondary)
                                            }
                                        }

                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    Spacer()

                    // MARK: - Restore Button
                    Button {
                        Haptic.medium()

                        groceryVM.clearAll()
                        history.items.forEach {
                            groceryVM.addItem(
                                name: $0.name,
                                quantity: $0.quantity
                            )
                        }

                        dismiss()
                    } label: {
                        Text("Restore This List")
                            .font(AppFont.subtitle(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColor.primary,
                                                AppColor.secondary
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(
                                color: .black.opacity(0.18),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
        }
    }
}
