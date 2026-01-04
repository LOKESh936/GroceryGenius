import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - Streaming chunk model (for SSE)
private struct ChatStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}

@MainActor
final class AIViewModel: ObservableObject {

    @Published var messages: [AIMsg] = []
    @Published var conversations: [AIConversation] = []

    // Streaming state
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""

    private let store = AIHistoryStore()

    private var lastUserPrompt: String?
    private var currentTask: Task<Void, Never>?

    // Per-user stable conversation id (active chat)
    private var conversationId: String = ""

    // Auth listener
    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentUID: String?

    var latestAIText: String? {
        messages.last(where: { !$0.isUser })?.text
    }

    init() {
        listenToAuth()
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Auth → setup + restore

    private func listenToAuth() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.currentUID = user?.uid
            self.messages = []
            self.streamingText = ""
            self.isStreaming = false

            guard let uid = user?.uid else {
                self.conversationId = ""
                self.conversations = []
                return
            }

            self.conversationId = self.loadOrCreateConversationId(uid: uid)

            Task {
                await self.loadConversations()
                await self.restoreHistory(uid: uid)
            }
        }
    }

    private func loadOrCreateConversationId(uid: String) -> String {
        let key = "ai_conversation_id_\(uid)"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    private func restoreHistory(uid: String) async {
        guard !conversationId.isEmpty else { return }
        do {
            let history = try await store.loadMessages(uid: uid, conversationId: conversationId)
            self.messages = history
        } catch {
            print("❌ Failed to load AI history:", error.localizedDescription)
        }
    }

    // ✅ Key fix: ensure the conversation document exists so chats list isn't empty
    private func ensureConversationExists(title: String) async {
        guard let uid = currentUID, !conversationId.isEmpty else { return }
        do {
            try await store.ensureConversationDocument(uid: uid, conversationId: conversationId, title: title)
            await loadConversations()
        } catch {
            print("❌ ensureConversationExists failed:", error.localizedDescription)
        }
    }

    // MARK: - Conversations API (sheet)

    func loadConversations() async {
        guard let uid = currentUID else { return }
        do {
            self.conversations = try await store.loadConversations(uid: uid)
        } catch {
            print("❌ Failed to load conversations:", error.localizedDescription)
        }
    }

    func startNewConversation(title: String) {
        guard let uid = currentUID else { return }

        Task {
            do {
                let newId = try await store.createConversation(uid: uid, title: title)
                conversationId = newId
                UserDefaults.standard.set(newId, forKey: "ai_conversation_id_\(uid)")

                self.messages.removeAll()
                self.streamingText = ""
                self.isStreaming = false
                self.lastUserPrompt = nil

                await loadConversations()
            } catch {
                print("❌ Failed to create conversation:", error.localizedDescription)
            }
        }
    }

    func switchConversation(_ convo: AIConversation) {
        guard let uid = currentUID else { return }

        conversationId = convo.id
        UserDefaults.standard.set(convo.id, forKey: "ai_conversation_id_\(uid)")

        messages = []
        streamingText = ""
        isStreaming = false
        lastUserPrompt = nil

        Task { await restoreHistory(uid: uid) }
    }

    func deleteConversation(_ convo: AIConversation) {
        guard let uid = currentUID else { return }

        Task {
            do {
                try await store.deleteConversation(uid: uid, conversationId: convo.id)

                // If user deleted the active one -> start a fresh new conversation id
                if convo.id == conversationId {
                    let fresh = UUID().uuidString
                    conversationId = fresh
                    UserDefaults.standard.set(fresh, forKey: "ai_conversation_id_\(uid)")

                    messages.removeAll()
                    streamingText = ""
                    isStreaming = false
                    lastUserPrompt = nil
                }

                await loadConversations()
            } catch {
                print("❌ deleteConversation failed:", error.localizedDescription)
            }
        }
    }

    // MARK: - Messaging API

    func sendMessage(_ text: String, groceries: [GroceryItem] = []) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let uid = currentUID, !conversationId.isEmpty else { return }

        // ✅ Ensure this conversation doc exists
        Task { await ensureConversationExists(title: String(trimmed.prefix(42))) }

        let userMessage = AIMsg(text: trimmed, isUser: true)
        messages.append(userMessage)
        lastUserPrompt = trimmed

        // persist user message
        Task { try? await store.saveMessage(uid: uid, conversationId: conversationId, message: userMessage) }

        currentTask?.cancel()
        isStreaming = true
        streamingText = ""

        currentTask = Task { [weak self] in
            await self?.streamFromOpenAI(prompt: trimmed, groceries: groceries)
        }
    }

    func stopStreaming() {
        currentTask?.cancel()
        isStreaming = false
        streamingText = ""
    }

    func clearChat() {
        currentTask?.cancel()
        isStreaming = false
        streamingText = ""
        lastUserPrompt = nil

        guard let uid = currentUID, !conversationId.isEmpty else {
            messages.removeAll()
            return
        }

        let snapshot = messages
        messages.removeAll()

        Task {
            do {
                try await store.clearConversation(uid: uid, conversationId: conversationId, messages: snapshot)
            } catch {
                print("❌ clearChat failed:", error.localizedDescription)
            }
        }
    }

    func regenerateLast(groceries: [GroceryItem] = []) {
        guard let lastPrompt = lastUserPrompt else { return }
        sendMessage(lastPrompt, groceries: groceries)
    }

    // MARK: - OpenAI Streaming (unchanged logic + save final AI msg)

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

                if let uid = currentUID, !conversationId.isEmpty {
                    Task { try? await store.saveMessage(uid: uid, conversationId: conversationId, message: aiMessage) }
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
