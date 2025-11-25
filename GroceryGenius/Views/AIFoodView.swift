import SwiftUI

struct AIFoodView: View {
    @StateObject private var vm = AIViewModel()
    @StateObject private var voice = VoiceInputManager()
    
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Chat Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // All messages (user + AI)
                        ForEach(vm.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // MARK: - Streaming bubble (“typing” + partial message)
                        if vm.isStreaming {
                            if vm.streamingText.isEmpty {
                                // Three-dot typing bubble
                                TypingBubbleView()
                            } else {
                                // Live streaming message bubble
                                MessageBubbleView(
                                    message: AIMsg(text: vm.streamingText, isUser: false)
                                )
                            }
                        }
                    }
                    .padding(.top, 12)
                }
                .background(Color(red: 0.97, green: 0.93, blue: 0.84))
                
                // MARK: - Auto Scroll to Bottom
                // New iOS 17-compatible version (no parameters)
                .onChange(of: vm.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: vm.streamingText) {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // MARK: - Recipe Card
            if let text = vm.latestAIText, !text.isEmpty {
                RecipeCardView(text: text)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Input Bar at bottom
            inputBar
                .background(
                    Color(red: 0.97, green: 0.93, blue: 0.84)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .onAppear {
            Task {
                _ = await voice.requestAuthorization()
            }
        }
    }
    
    // MARK: - Scroll Logic
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = vm.messages.last {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    // MARK: - Input Bar (mic + textfield + send)
    private var inputBar: some View {
        HStack(spacing: 10) {
            
            // ---------- MIC BUTTON ----------
            Button {
                if voice.isRecording {
                    voice.stopRecording()
                } else {
                    voice.startRecording { text in
                        self.inputText = text
                    }
                }
            } label: {
                Image(systemName: voice.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(voice.isRecording ? .red : .orange)
            }
            
            // ---------- TEXT FIELD ----------
            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    Text("Ask for a meal plan…")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 14)
                }
                
                TextField("", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            // ---------- SEND BUTTON ----------
            Button {
                let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                
                vm.sendMessage(text)
                inputText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
