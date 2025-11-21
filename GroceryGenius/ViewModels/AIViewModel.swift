import SwiftUI

class AIViewModel: ObservableObject {
    @Published var messages: [AIMsg] = []
    
    func sendMessage(_ text: String) {
        let userMessage = AIMsg(text: text, isUser: true)
        messages.append(userMessage)
        
        // Temporary AI reply (we will replace with real API later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiMessage = AIMsg(text: "Here is a sample meal plan based on your groceries!", isUser: false)
            self.messages.append(aiMessage)
        }
    }
}
