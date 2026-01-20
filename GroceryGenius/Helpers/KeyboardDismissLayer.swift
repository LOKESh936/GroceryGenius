import SwiftUI

struct KeyboardDismissLayer: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }

            content
        }
    }
}

extension View {
    func keyboardDismissable() -> some View {
        modifier(KeyboardDismissLayer())
    }
}
