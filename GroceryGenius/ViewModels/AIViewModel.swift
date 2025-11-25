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
    
    // For streaming / typing effect
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""
    
    // Simple derived “recipe card” – last AI reply
    var latestAIText: String? {
        messages.last(where: { !$0.isUser })?.text
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = AIMsg(text: text, isUser: true)
        messages.append(userMessage)
        
        Task {
            await streamFromOpenAI(prompt: text)
        }
    }
    
    // MARK: - Streaming Chat Completions
    
    private func streamFromOpenAI(prompt: String) async {
        // 1️⃣ Read from environment variable
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
              !apiKey.isEmpty else {
            print("❌ Missing OPENAI_API_KEY environment variable")
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
                    You are GroceryGenius, an AI that creates friendly, practical meal plans \
                    from groceries. Respond in short, structured Markdown. Use headings \
                    (### Day 1, ### Breakfast, etc.) and bullet lists.
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
            print("❌ Streaming error:", error.localizedDescription)
        }
        
        streamingText = ""
        isStreaming = false
    }
}
