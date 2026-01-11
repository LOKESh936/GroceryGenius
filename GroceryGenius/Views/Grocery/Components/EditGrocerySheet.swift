import SwiftUI

struct EditGrocerySheet: View {

    let item: GroceryItem
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: String

    @FocusState private var focusedField: Field?

    enum Field {
        case name, quantity
    }

    // MARK: - Init

    init(
        item: GroceryItem,
        onSave: @escaping (String, String) -> Void
    ) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {

                    // Item name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Item name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)

                        TextField("Name", text: $name)
                            .focused($focusedField, equals: .name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(false)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(fieldBackground)
                            .overlay(fieldStroke)
                            .cornerRadius(14)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .quantity
                            }
                    }

                    // Quantity
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quantity")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)

                        TextField("e.g. 2 lbs, 1 pack", text: $quantity)
                            .focused($focusedField, equals: .quantity)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(fieldBackground)
                            .overlay(fieldStroke)
                            .cornerRadius(14)
                            .submitLabel(.done)
                            .onSubmit {
                                save()
                            }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Cancel
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptic.light()
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primary)
                }

                // Save
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focusedField = .name
                }
            }
        }
    }

    // MARK: - Helpers

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQty  = quantity.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            Haptic.light()
            focusedField = .name
            return
        }

        Haptic.medium()
        onSave(trimmedName, trimmedQty)
        dismiss()
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(AppColor.cardBackground.opacity(0.6))
    }

    private var fieldStroke: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
    }
}
