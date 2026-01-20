import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// ✅ Apply once to any screen/sheet that needs "tap outside to dismiss"
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    hideKeyboard()
                }
            )
    }
}
#endif
