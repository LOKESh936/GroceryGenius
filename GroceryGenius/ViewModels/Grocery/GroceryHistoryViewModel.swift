import Foundation
import FirebaseAuth

@MainActor
final class GroceryHistoryViewModel: ObservableObject {

    @Published var history: [GroceryHistory] = []

    private let store = GroceryHistoryStore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    func load() async {
        guard let uid else { return }
        history = (try? await store.loadHistory(uid: uid)) ?? []
    }

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

    func delete(_ history: GroceryHistory) async {
        guard let uid else { return }
        try? await store.deleteHistory(uid: uid, id: history.id)
        await load()
    }

    func rename(_ history: GroceryHistory, title: String) async {
        guard let uid else { return }
        try? await store.renameHistory(uid: uid, id: history.id, title: title)
        await load()
    }
}
