import Foundation
import SwiftUI

// MARK: - Streaming chunk model (for SSE)
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
    @Published var messages: [AIMsg] = []

    // Streaming state
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""

    // For "Regenerate" feature later
    private var lastUserPrompt: String?
    private var currentTask: Task<Void, Never>?

    // Last AI message text (used if we ever want recipe cards again)
    var latestAIText: String? {
        messages.last(where: { !$0.isUser })?.text
    }

    // MARK: - Public API

    /// Main entry point for sending a message.
    /// `groceries` is the current list of items from the Grocery tab.
    func sendMessage(_ text: String, groceries: [GroceryItem] = []) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Save user message into chat history
        let userMessage = AIMsg(text: trimmed, isUser: true)
        messages.append(userMessage)
        lastUserPrompt = trimmed

        // Cancel any previous streaming task
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
        messages.removeAll()
        streamingText = ""
        isStreaming = false
        lastUserPrompt = nil
    }

    /// Optional: regenerate last answer (keeps same conversation + groceries).
    func regenerateLast(groceries: [GroceryItem] = []) {
        guard let lastPrompt = lastUserPrompt else { return }
        sendMessage(lastPrompt, groceries: groceries)
    }

    // MARK: - OpenAI Streaming

    private func streamFromOpenAI(prompt: String, groceries: [GroceryItem]) async {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("❌ Missing OPENAI_API_KEY in Info.plist")
            isStreaming = false
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        // ---- Build grocery context -------------------------------------------------
        let groceryContext: String
        if groceries.isEmpty {
            groceryContext = """
            The user has not provided a grocery list. Suggest realistic, budget-friendly meals \
            that use ingredients commonly available in a student kitchen.
            """
        } else {
            let itemsText = groceries.map { item in
                if item.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return item.name
                } else {
                    return "\(item.quantity) × \(item.name)"
                }
            }
            .joined(separator: ", ")

            groceryContext = """
            Here is the user's current grocery inventory (name and optional quantity):

            \(itemsText)

            Always prefer using these items first. Only add extra ingredients when necessary.
            """
        }

        // ---- System prompt: style + formatting rules ------------------------------
        let systemContent = """
        You are **GroceryGenius**, a friendly AI nutrition assistant.

        Goals:
        - Create practical meal plans and recipes suitable for a busy student.
        - Prefer using the user's existing groceries.
        - Keep the tone warm, encouraging, and concise.

        Formatting rules (VERY IMPORTANT):
        - Respond in **Markdown**.
        - Use clear headings, for example:
          - `## Day 1`, `## Day 2`
          - `### Breakfast`, `### Lunch`, `### Snack`, `### Dinner`
        - Use bullet lists for ingredients and steps:
          - `- Ingredient`
          - `- Step`
        - Put each bullet on its **own line**.
        - Avoid long wall-of-text paragraphs. Break content into short sections.
        - Highlight important words with **bold** occasionally (not too much).

        \(groceryContext)
        """

        // Take the last few turns of the conversation for context
        let historyMessages: [[String: String]] = messages.suffix(8).map { msg in
            [
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text
            ]
        }

        var chatMessages: [[String: String]] = [
            ["role": "system", "content": systemContent]
        ]
        chatMessages.append(contentsOf: historyMessages)
        chatMessages.append([
            "role": "user",
            "content": prompt
        ])

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

                // OpenAI streaming lines look like: "data: {json}"
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))

                if payload == "[DONE]" {
                    break
                }

                guard let data = payload.data(using: .utf8) else { continue }

                if let chunk = try? JSONDecoder().decode(ChatStreamChunk.self, from: data),
                   let delta = chunk.choices.first?.delta.content,
                   !delta.isEmpty {
                    streamingText.append(delta)
                } else {
                    // If this was an error payload, just print it for debugging
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("🌐 RAW RESPONSE CHUNK:", json)
                    }
                }
            }

            let finalText = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalText.isEmpty {
                let aiMessage = AIMsg(text: finalText, isUser: false)
                messages.append(aiMessage)
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
