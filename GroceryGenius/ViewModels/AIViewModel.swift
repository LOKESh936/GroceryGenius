import Foundation
import SwiftUI

// MARK: - Streaming models

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
class AIViewModel: ObservableObject {
    @Published var messages: [AIMsg] = []
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""

    // Keep a handle to the current streaming task so we can cancel it (Stop button)
    private var currentTask: Task<Void, Never>?

    // Last AI message in the history
    var latestAIMessage: AIMsg? {
        messages.last(where: { !$0.isUser })
    }

    // Text used by the recipe card
    var latestAIText: String? {
        latestAIMessage?.text
    }

    // Last user prompt (for Regenerate)
    var lastUserPrompt: String? {
        messages.last(where: { $0.isUser })?.text
    }

    // MARK: - Public actions

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = AIMsg(text: trimmed, isUser: true)
        messages.append(userMessage)

        // Cancel any previous stream and start a new one
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            await self?.streamFromOpenAI(prompt: trimmed)
        }
    }

    func stopStreaming() {
        currentTask?.cancel()
        currentTask = nil
        isStreaming = false
    }

    func clearChat() {
        currentTask?.cancel()
        currentTask = nil
        messages.removeAll()
        streamingText = ""
        isStreaming = false
    }

    func regenerateLast() {
        guard let prompt = lastUserPrompt else { return }
        sendMessage(prompt)
    }

    // MARK: - Streaming Chat Completions

    private func streamFromOpenAI(prompt: String) async {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !apiKey.isEmpty
        else {
            print("❌ Missing OPENAI_API_KEY in Info.plist")
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "stream": true,
            "messages": [
                        [
                            "role": "system",
                            "content": """
                            You are **GroceryGenius**, an AI nutrition coach that creates friendly, \
                            practical meal plans.

                            FORMAT RULES (very important):
                            - Always answer in clean, readable **Markdown** (for a mobile chat UI).
                            - Start with a short title, e.g. `## 1-Day Balanced Meal Plan`.
                            - For each day use a heading: `### Day 1`, `### Day 2`, etc.
                            - Inside each day, use bold meal labels and bullet lists, like:

                              **Breakfast**
                              - Item 1
                              - Item 2

                              **Lunch**
                              - Item 1
                              - Item 2

                            - Put a blank line between headings, paragraphs, and bullet sections.
                            - Keep sentences short. Avoid giant paragraphs.
                            - At the end, add a small tips section, e.g.:

                              **Tips**
                              - Tip 1
                              - Tip 2

                            - Do NOT use code blocks, tables, or numbered lists unless the user asks.
                            - Stay friendly, concise, and practical.
                            """
                    ],
                    [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to encode JSON body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        isStreaming = true
        streamingText = ""

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)

            for try await line in bytes.lines {
                if Task.isCancelled { break }

                // Server-Sent Events format: lines starting with "data: "
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
                }
            }

            let finalText = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalText.isEmpty {
                let aiMsg = AIMsg(text: finalText, isUser: false)
                messages.append(aiMsg)
            }
        } catch {
            if !Task.isCancelled {
                print("❌ Streaming error:", error.localizedDescription)
            }
        }

        streamingText = ""
        isStreaming = false
        currentTask = nil
    }
}
