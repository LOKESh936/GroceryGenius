import Foundation

final class ProEntitlementStore: ObservableObject {

    static let shared = ProEntitlementStore()

    @Published var isProUser: Bool = false

    private init() {}
}
