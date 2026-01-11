import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// MARK: - Streaming chunk model
private struct ChatStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}

@MainActor
final class AIViewModel: ObservableObject {

    // MARK: - Published (UI)

    @Published var messages: [AIMsg] = []
    @Published var conversations: [AIConversation] = []

    @Published var activeConversationId: String?
    @Published var activeConversationTitle: String = "AI Meals"

    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""

    // MARK: - Private

    private let store = AIHistoryStore()
    private var lastUserPrompt: String?
    private var currentTask: Task<Void, Never>?

    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentUID: String?

    // MARK: - Init / Deinit

    init() {
        listenToAuth()
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Auth

    private func listenToAuth() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.currentUID = user?.uid
            self.messages.removeAll()
            self.streamingText = ""
            self.isStreaming = false

            guard let uid = user?.uid else {
                self.activeConversationId = nil
                self.conversations = []
                return
            }

            let key = "ai_active_conversation_\(uid)"

            if let saved = UserDefaults.standard.string(forKey: key) {
                self.activeConversationId = saved
            } else {
                let fresh = UUID().uuidString
                self.activeConversationId = fresh
                UserDefaults.standard.set(fresh, forKey: key)
                self.activeConversationTitle = "New meal plan"
            }

            Task {
                // ✅ Ensure Firestore doc exists for the active conversation (prevents missing chats)
                if let convoId = self.activeConversationId {
                    try? await self.store.ensureConversationExists(
                        uid: uid,
                        conversationId: convoId,
                        titleIfMissing: self.activeConversationTitle.isEmpty ? "New meal plan" : self.activeConversationTitle
                    )
                }

                await self.loadConversations()
                self.syncActiveConversationTitle()
                await self.restoreMessages()
            }
        }
    }

    // MARK: - Conversations

    func loadConversations() async {
        guard let uid = currentUID else { return }
        do {
            conversations = try await store.loadConversations(uid: uid)
        } catch {
            print("❌ loadConversations:", error.localizedDescription)
        }
    }

    func startNewConversation(title: String) {
        guard let uid = currentUID else { return }

        Task {
            do {
                let newId = try await store.createConversation(uid: uid, title: title)

                activeConversationId = newId
                activeConversationTitle = title
                UserDefaults.standard.set(newId, forKey: "ai_active_conversation_\(uid)")

                messages.removeAll()
                lastUserPrompt = nil
                streamingText = ""
                isStreaming = false

                await loadConversations()
            } catch {
                print("❌ startNewConversation:", error.localizedDescription)
            }
        }
    }

    func switchConversation(_ convo: AIConversation) {
        guard let uid = currentUID else { return }

        activeConversationId = convo.id
        activeConversationTitle = convo.title
        UserDefaults.standard.set(convo.id, forKey: "ai_active_conversation_\(uid)")

        messages.removeAll()
        lastUserPrompt = nil
        streamingText = ""
        isStreaming = false

        Task {
            await restoreMessages()
        }
    }

    func deleteConversation(_ convo: AIConversation) {
        guard let uid = currentUID else { return }

        Task {
            do {
                try await store.deleteConversation(uid: uid, conversationId: convo.id)

                if convo.id == activeConversationId {
                    let fresh = UUID().uuidString
                    activeConversationId = fresh
                    activeConversationTitle = "New meal plan"
                    UserDefaults.standard.set(fresh, forKey: "ai_active_conversation_\(uid)")
                    messages.removeAll()

                    // ✅ create missing doc so it shows in list later
                    try? await store.ensureConversationExists(
                        uid: uid,
                        conversationId: fresh,
                        titleIfMissing: "New meal plan"
                    )
                }

                await loadConversations()
                syncActiveConversationTitle()
            } catch {
                print("❌ deleteConversation:", error.localizedDescription)
            }
        }
    }

    /// ✅ Rename (called from AIConversationsSheet)
    func renameConversation(_ convo: AIConversation, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let uid = currentUID else { return }

        // optimistic UI update
        if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
            let updated = AIConversation(
                id: convo.id,
                title: trimmed,
                lastMessage: conversations[idx].lastMessage,
                createdAt: conversations[idx].createdAt
            )
            conversations[idx] = updated
        }

        if convo.id == activeConversationId {
            activeConversationTitle = trimmed
        }

        Task {
            do {
                try await store.updateConversationMetadata(
                    uid: uid,
                    conversationId: convo.id,
                    title: trimmed,
                    lastMessage: nil
                )
                await loadConversations()
                syncActiveConversationTitle()
            } catch {
                print("❌ renameConversation:", error.localizedDescription)
            }
        }
    }

    private func syncActiveConversationTitle() {
        guard let activeConversationId else { return }
        if let convo = conversations.first(where: { $0.id == activeConversationId }) {
            activeConversationTitle = convo.title
        }
    }

    // MARK: - Restore Messages

    private func restoreMessages() async {
        guard let uid = currentUID,
              let convoId = activeConversationId else { return }

        do {
            messages = try await store.loadMessages(uid: uid, conversationId: convoId)
        } catch {
            print("❌ restoreMessages:", error.localizedDescription)
        }
    }

    // MARK: - Messaging

    func sendMessage(_ text: String, groceries: [GroceryItem] = []) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let uid = currentUID,
              let convoId = activeConversationId else { return }

        let userMessage = AIMsg(text: trimmed, isUser: true)
        messages.append(userMessage)
        lastUserPrompt = trimmed

        Task {
            // ensure convo exists
            try? await store.ensureConversationExists(
                uid: uid,
                conversationId: convoId,
                titleIfMissing: activeConversationTitle.isEmpty ? "New meal plan" : activeConversationTitle
            )

            try? await store.saveMessage(uid: uid, conversationId: convoId, message: userMessage)

            // ✅ lastMessage preview
            try? await store.updateConversationMetadata(
                uid: uid,
                conversationId: convoId,
                title: nil,
                lastMessage: trimmed
            )
        }

        currentTask?.cancel()
        isStreaming = true
        streamingText = ""

        currentTask = Task { [weak self] in
            await self?.streamFromOpenAI(prompt: trimmed, groceries: groceries)
        }
    }

    func clearChat() {
        currentTask?.cancel()
        isStreaming = false
        streamingText = ""
        lastUserPrompt = nil

        guard let uid = currentUID,
              let convoId = activeConversationId else {
            messages.removeAll()
            return
        }

        let snapshot = messages
        messages.removeAll()

        Task {
            try? await store.clearConversation(
                uid: uid,
                conversationId: convoId,
                messages: snapshot
            )

            // reset preview when cleared
            try? await store.updateConversationMetadata(
                uid: uid,
                conversationId: convoId,
                title: nil,
                lastMessage: ""
            )

            await loadConversations()
            syncActiveConversationTitle()
        }
    }

    func regenerateLast(groceries: [GroceryItem] = []) {
        guard let lastUserPrompt else { return }
        sendMessage(lastUserPrompt, groceries: groceries)
    }

    // MARK: - Helpers (title + preview)

    private func makePreview(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= 90 { return cleaned }
        let idx = cleaned.index(cleaned.startIndex, offsetBy: 90)
        return String(cleaned[..<idx])
    }

    private func shouldAutoRenameCurrentChat() -> Bool {
        let t = activeConversationTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return t.isEmpty || t == "new meal plan" || t == "ai meals"
    }

    private func autoRenameTitle(from prompt: String) -> String {
        let cleaned = prompt
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty { return "Meal plan" }
        if cleaned.count <= 28 { return cleaned }

        let idx = cleaned.index(cleaned.startIndex, offsetBy: 28)
        return String(cleaned[..<idx]) + "…"
    }

    // MARK: - OpenAI Streaming (save final AI msg + update lastMessage + auto-rename)

    private func streamFromOpenAI(prompt: String, groceries: [GroceryItem]) async {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("❌ Missing OPENAI_API_KEY in Info.plist")
            isStreaming = false
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let groceryContext: String
        if groceries.isEmpty {
            groceryContext = """
            The user has not provided a grocery list. Suggest realistic, budget-friendly meals \
            that use ingredients commonly available in a student kitchen.
            """
        } else {
            let itemsText = groceries.map { item in
                item.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? item.name
                : "\(item.quantity) × \(item.name)"
            }
            .joined(separator: ", ")

            groceryContext = """
            Here is the user's current grocery inventory (name and optional quantity):

            \(itemsText)

            Always prefer using these items first. Only add extra ingredients when necessary \
            and try to minimize food waste.
            """
        }

        let systemContent = """
        
        You are **GroceryGenius**, an in-app meal-planning and grocery assistant.

        Your goals:
        - Create realistic, student-friendly meal plans that are quick and affordable.
        - Prefer using ingredients from the user's existing grocery inventory.
        - Keep instructions simple enough for beginner cooks.

        STRICT FORMATTING RULES (always answer in **Markdown**):

        1. Start with a SHORT 1–2 sentence intro describing what the plan covers.
        2. Then create sections per day using level-3 headings on their own lines, for example:
            `### Day 1`
            `### Day 2`
            and so on.
        3. Inside each day, always include these sub-headings in this order:
            `#### Breakfast`
            `#### Lunch`
            `#### Dinner`
            `#### Snacks` (only include if there are snacks).
        4. Under each sub-heading, use bullet points in this style:
            - **Meal name** — short description + ingredient list with approximate quantities
                (e.g. `- **Oatmeal with berries** — 1/2 cup oats, 1/2 cup milk, 1/4 cup berries`).
        5. Put a blank line:
            - between each section (Breakfast/Lunch/Dinner/Snacks),
            - and between each day.
        6. NEVER join the day title and the first meal on a single line.
            For example, do **NOT** write `Day 1Breakfast...`.
        7. When possible:
            - Reuse ingredients across multiple meals to save money and reduce waste.
            - Offer simple optional swaps (e.g. “Swap chicken for tofu to make this vegetarian.”).
        8. If the user mentions a preference or constraint (e.g. high protein, vegetarian, Indian,
            no dairy, etc.), adapt the meals to fit that while still following all formatting rules.
        User inventory / context:
        \(groceryContext)
        """

        let historyMessages: [[String: String]] = messages.suffix(8).map { msg in
            ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
        }

        var chatMessages: [[String: String]] = [["role": "system", "content": systemContent]]
        chatMessages.append(contentsOf: historyMessages)
        chatMessages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "stream": true,
            "temperature": 0.6,
            "messages": chatMessages
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to encode JSON body")
            isStreaming = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        streamingText = ""
        isStreaming = true

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                guard line.hasPrefix("data: ") else { continue }

                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }
                guard let data = payload.data(using: .utf8) else { continue }

                if let chunk = try? JSONDecoder().decode(ChatStreamChunk.self, from: data),
                   let delta = chunk.choices.first?.delta.content,
                   !delta.isEmpty {
                    streamingText.append(delta)
                }
            }

            let finalText = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalText.isEmpty {
                let aiMessage = AIMsg(text: finalText, isUser: false)
                messages.append(aiMessage)

                if let uid = currentUID, let convoId = activeConversationId {
                    let preview = makePreview(from: finalText)

                    Task {
                        try? await store.saveMessage(uid: uid, conversationId: convoId, message: aiMessage)

                        // ✅ update lastMessage preview for list
                        try? await store.updateConversationMetadata(
                            uid: uid,
                            conversationId: convoId,
                            title: nil,
                            lastMessage: preview
                        )

                        // ✅ auto-rename if it's still default
                        if shouldAutoRenameCurrentChat() {
                            let newTitle = autoRenameTitle(from: prompt)

                            // optimistic UI update
                            activeConversationTitle = newTitle

                            try? await store.updateConversationMetadata(
                                uid: uid,
                                conversationId: convoId,
                                title: newTitle,
                                lastMessage: nil
                            )
                        }

                        await loadConversations()
                        syncActiveConversationTitle()
                    }
                }
            }
        } catch {
            if !Task.isCancelled {
                print("❌ Streaming error:", error.localizedDescription)
            }
        }

        streamingText = ""
        isStreaming = false
    }
}


