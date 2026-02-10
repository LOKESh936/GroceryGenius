import Foundation

enum AIUsageTier {
    case free
    case pro
}

struct AIUsagePolicy {
    static let freeDailyLimit = 5   // ← change later
}
