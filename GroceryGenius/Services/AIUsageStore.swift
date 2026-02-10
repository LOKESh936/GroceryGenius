import Foundation
import SwiftUI

@MainActor
final class AIUsageStore: ObservableObject {

    @Published private(set) var dailyCount: Int = 0
    @Published private(set) var lastResetDate: Date?

    func incrementUsage() {
        // future: increment counter
    }

    func resetIfNeeded() {
        // future: reset daily
    }

    var remainingFreeUses: Int {
        AIUsagePolicy.freeDailyLimit - dailyCount
    }
}
