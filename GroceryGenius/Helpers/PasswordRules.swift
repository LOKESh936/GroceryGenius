import Foundation

struct PasswordRules {

    // MARK: - Precompiled regex (performance-safe)

    private static let uppercaseRegex = try! NSRegularExpression(pattern: "[A-Z]")
    private static let lowercaseRegex = try! NSRegularExpression(pattern: "[a-z]")
    private static let numberRegex    = try! NSRegularExpression(pattern: "[0-9]")
    private static let specialRegex   = try! NSRegularExpression(pattern: "[^A-Za-z0-9]")

    // MARK: - Score (0...4)

    static func score(_ password: String) -> Int {
        guard !password.isEmpty else { return 0 }

        var points = 0

        if password.count >= 8 { points += 1 }
        if matches(uppercaseRegex, password) { points += 1 }
        if matches(lowercaseRegex, password) { points += 1 }
        if matches(numberRegex, password) || matches(specialRegex, password) {
            points += 1
        }

        return points
    }

    // MARK: - Label

    static func label(for score: Int) -> String {
        switch score {
        case 0, 1:
            return "Weak"
        case 2:
            return "Fair"
        case 3:
            return "Strong"
        default:
            return "Very strong"
        }
    }

    // MARK: - Validity

    static func isValid(_ password: String) -> Bool {
        score(password) >= 3
    }

    // MARK: - Helper

    private static func matches(_ regex: NSRegularExpression, _ text: String) -> Bool {
        regex.firstMatch(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) != nil
    }
}
