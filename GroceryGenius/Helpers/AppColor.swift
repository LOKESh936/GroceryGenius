import SwiftUI
import UIKit

struct AppColor {

    // Core palette (brand)
    static let primary    = Color.fromHex("#628141")
    static let secondary  = Color.fromHex("#8BAE66")
    static let accent     = Color.fromHex("#E67E22")

    // Background becomes darker in dark mode (same warm family)
    static let background = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1.0) // warm deep
        } else {
            return UIColor(red: 0.92, green: 0.84, blue: 0.67, alpha: 1.0) // #EBD5AB-ish
        }
    })

    // ✅ Dynamic text colors (fixes unreadable dark mode text)
    static let textPrimary   = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)

    // ✅ Tonal surfaces (adapt in dark mode)
    static let cardBackground = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.19, blue: 0.16, alpha: 1.0)
        } else {
            return UIColor(red: 0.95, green: 0.89, blue: 0.78, alpha: 1.0) // #F1E4C6-ish
        }
    })

    static let cardElevated = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.24, green: 0.23, blue: 0.20, alpha: 1.0)
        } else {
            return UIColor(red: 0.97, green: 0.92, blue: 0.83, alpha: 1.0) // #F6EBD3-ish
        }
    })

    // Divider adapts
    static let divider = Color(uiColor: .separator)

    // Small “chrome” surfaces used for circular buttons etc.
    static let chromeSurface = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor.white.withAlphaComponent(0.10)
        } else {
            return UIColor.white.withAlphaComponent(0.65)
        }
    })

    // Chat specific
    static let aiBubble = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.22, green: 0.21, blue: 0.18, alpha: 1.0)
        } else {
            return UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: 1.0)
        }
    })

    static let userBubble = accent.opacity(0.92)
}
