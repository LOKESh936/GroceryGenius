import SwiftUI

struct AppColor {

    // Core palette
    static let primary    = Color.fromHex("#628141") // deep green
    static let secondary  = Color.fromHex("#8BAE66") // lighter green
    static let accent     = Color.fromHex("#E67E22") // orange
    static let background = Color.fromHex("#EBD5AB") // warm beige

    // Text
    static let textPrimary   = Color.black.opacity(0.85)
    static let textSecondary = Color.black.opacity(0.6)

    // ✅ TONAL surfaces (NOT white)
    static let cardBackground =
        Color.fromHex("#F1E4C6") // lighter beige, same hue family

    static let cardElevated =
        Color.fromHex("#F6EBD3") // slightly lighter for inputs / bubbles

    static let divider =
        Color.black.opacity(0.08)

    // Chat specific
    static let aiBubble =
        Color.fromHex("#F3E7C8")

    static let userBubble =
        Color.fromHex("#E67E22").opacity(0.92)
}
