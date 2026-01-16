import Foundation
import FirebaseAuth

@MainActor
final class GroceryHistoryViewModel: ObservableObject {

    enum SortOption: String, CaseIterable, Identifiable {
        case newest
        case oldest
        case name

        var id: String { rawValue }

        var title: String {
            switch self {
            case .newest: return "Newest first"
            case .oldest: return "Oldest first"
            case .name:   return "Name A–Z"
            }
        }
    }

    @Published var history: [GroceryHistory] = []
    @Published var sort: SortOption = .newest

    private let store = GroceryHistoryStore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Load
    func load() async {
        guard let uid else { return }
        let data = (try? await store.loadHistory(uid: uid)) ?? []
        history = sortHistory(data)
    }

    // MARK: - Save
    func saveFromCurrentList(items: [GroceryItem], title: String) async {
        guard let uid else { return }

        let history = GroceryHistory(
            id: UUID().uuidString,
            title: title,
            completedAt: Date(),
            items: items
        )

        try? await store.saveHistory(uid: uid, history: history)
        await load()
    }

    // MARK: - Delete
    func delete(_ history: GroceryHistory) async {
        guard let uid else { return }
        try? await store.deleteHistory(uid: uid, id: history.id)
        await load()
    }

    // MARK: - Rename
    func rename(_ history: GroceryHistory, title: String) async {
        guard let uid else { return }
        try? await store.renameHistory(uid: uid, id: history.id, title: title)
        await load()
    }

    // MARK: - Duplicate
    func duplicate(_ history: GroceryHistory) async {
        guard let uid else { return }

        let copy = GroceryHistory(
            id: UUID().uuidString,
            title: "\(history.title) Copy",
            completedAt: Date(),
            items: history.items
        )

        try? await store.saveHistory(uid: uid, history: copy)
        await load()
    }

    // MARK: - Sorting
    func setSort(_ option: SortOption) {
        sort = option
        history = sortHistory(history)
    }

    private func sortHistory(_ data: [GroceryHistory]) -> [GroceryHistory] {
        switch sort {
        case .newest:
            return data.sorted { $0.completedAt > $1.completedAt }
        case .oldest:
            return data.sorted { $0.completedAt < $1.completedAt }
        case .name:
            return data.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
