//
//  AIService.swift
//  GroceryGenius
//

import Foundation

struct AIStreamResponse {
    let text: String
}

/// Handles communication with OpenAI API (streaming).
final class AIService {

    private let apiKey: String

    init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty else {
            fatalError("❌ OPENAI_API_KEY missing in Info.plist")
        }
        self.apiKey = key
    }

    /// Sends a chat request and returns an async sequence of text chunks.
    func streamResponse(messages: [[String: String]]) async throws -> AsyncThrowingStream<String, Error> {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "stream": true,
            "temperature": 0.6,
            "messages": messages
        ]

        let json = try JSONSerialization.data(withJSONObject: body)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = json
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (bytes, _) = try await URLSession.shared.bytes(for: req)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let raw = String(line.dropFirst(6))
                            if raw == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            if let data = raw.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(ChatStreamChunk.self, from: data),
                               let delta = chunk.choices.first?.delta.content {
                                continuation.yield(delta)
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// Internal streaming model reused from AIViewModel
private struct ChatStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}
