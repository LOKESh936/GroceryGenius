import SwiftUI

struct SecureInputField: View {

    let title: String
    @Binding var text: String

    @State private var isSecure: Bool = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .foregroundStyle(AppColor.textPrimary)

            Button {
                isSecure.toggle()
                Haptic.light()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColor.cardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFocused
                    ? AppColor.primary.opacity(0.35)
                    : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
