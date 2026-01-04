import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class GroceryViewModel: ObservableObject {

    @Published var items: [GroceryItem] = []
    @Published var errorMessage: String?

    private let store = GroceryStore()

    private var authListener: AuthStateDidChangeListenerHandle?
    private var groceriesListener: ListenerRegistration?

    private var currentUID: String?

    init() {
        listenToAuth()
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
        groceriesListener?.remove()
    }

    // MARK: - Auth → attach groceries listener per user

    private func listenToAuth() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            // detach old listener
            self.groceriesListener?.remove()
            self.groceriesListener = nil
            self.items = []
            self.errorMessage = nil

            guard let user else {
                self.currentUID = nil
                return
            }

            self.currentUID = user.uid
            self.attachGroceriesListener(uid: user.uid)
        }
    }

    private func attachGroceriesListener(uid: String) {
        groceriesListener = store.listenGroceries(
            uid: uid,
            onChange: { [weak self] newItems in
                Task { @MainActor in
                    self?.items = newItems
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                }
            }
        )
    }

    // MARK: - Public API (used by your UI)

    func addItem(name: String, quantity: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let uid = currentUID else { return }

        let newItem = GroceryItem(
            name: trimmedName,
            quantity: quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        Task {
            do {
                try await store.addItem(uid: uid, item: newItem)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func toggleCompletion(for id: UUID) {
        guard let uid = currentUID else { return }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        var updated = items[index]
        updated.isCompleted.toggle()

        Task {
            do {
                try await store.updateItem(uid: uid, item: updated)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func delete(_ item: GroceryItem) {
        guard let uid = currentUID else { return }

        Task {
            do {
                try await store.deleteItem(uid: uid, itemID: item.id)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func update(itemID: UUID, name: String, quantity: String) {
        guard let uid = currentUID else { return }
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        var updated = items[index]
        updated.name = trimmedName
        updated.quantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await store.updateItem(uid: uid, item: updated)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func clearAll() {
        guard let uid = currentUID else { return }
        let snapshot = items

        Task {
            do {
                try await store.clearAll(uid: uid, items: snapshot)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
