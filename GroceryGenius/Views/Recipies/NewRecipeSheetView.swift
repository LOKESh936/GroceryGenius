import SwiftUI

struct NewRecipeSheetView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 16) {

                    SectionHeader(
                        title: "New Recipe",
                        subtitle: "Create a recipe to reuse later."
                    )
                    .padding(.top, 10)

                    GGCard {
                        VStack(alignment: .leading, spacing: 10) {

                            Text("Recipe title")
                                .font(AppFont.caption(12))
                                .foregroundStyle(AppColor.textSecondary)

                            TextField("e.g., Chicken Rice Bowl", text: $title)
                                .font(AppFont.body(16))
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(12)
                                .background(AppColor.cardElevated)
                                .cornerRadius(12)

                            Divider().opacity(0.35)

                            Text("Notes (optional)")
                                .font(AppFont.caption(12))
                                .foregroundStyle(AppColor.textSecondary)

                            TextEditor(text: $notes)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(AppColor.textPrimary)
                                .frame(minHeight: 140)
                                .padding(10)
                                .background(AppColor.cardElevated)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Bottom primary action (UI-only for now)
                    Button {
                        // For UI stage: just close
                        Haptic.medium()
                        dismiss()
                    } label: {
                        Text("Create")
                            .font(AppFont.subtitle(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColor.primary.opacity(0.45) : AppColor.primary)
                                    .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 5)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 6)
            }
            .navigationTitle("New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
        }
    }
}

#Preview {
    NewRecipeSheetView()
}
