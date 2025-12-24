import SwiftUI
import AVFoundation

struct AIFoodView: View {

    // MARK: - State & Dependencies

    @EnvironmentObject var vm: AIViewModel
    @StateObject private var voice = VoiceInputManager()

    @EnvironmentObject var groceryViewModel: GroceryViewModel

    @State private var inputText: String = ""
    @State private var isNearBottom: Bool = true
    @State private var showScrollToBottom: Bool = false
    @State private var shouldAutoScroll = true

    private let bottomID = "BOTTOM_ANCHOR"

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Chat
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            // Empty state
                            if vm.messages.isEmpty && !vm.isStreaming {
                                emptyState
                                    .padding(.horizontal, 16)
                                    .padding(.top, 28)
                            }

                            // Messages
                            ForEach(vm.messages) { msg in
                                AIMessageBubbleView(
                                    message: msg,
                                    onCopy: {
                                        UIPasteboard.general.string = msg.text
                                        Haptic.success()
                                    },
                                    onSpeak: {
                                        speak(msg.text)
                                    },
                                    onAddItems: {
                                        addAssistantMessageToGrocery(msg.text)
                                    }
                                )
                                .id(msg.id)
                                .padding(.horizontal, 16)
                            }

                            // Streaming message
                            if vm.isStreaming {
                                if vm.streamingText.isEmpty {
                                    AITypingIndicatorView()
                                        .padding(.horizontal, 16)
                                } else {
                                    AIMessageBubbleView(
                                        message: AIMsg(text: vm.streamingText, isUser: false),
                                        isStreaming: true,
                                        onCopy: {
                                            UIPasteboard.general.string = vm.streamingText
                                            Haptic.success()
                                        },
                                        onSpeak: {
                                            speak(vm.streamingText)
                                        },
                                        onAddItems: {
                                            addAssistantMessageToGrocery(vm.streamingText)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }

                            // Bottom visibility detector
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .named("AIChatScroll")).minY) { _, _ in
                                        // When the bottom anchor's minY is close to the viewport bottom, we are at bottom
                                        let minY = geo.frame(in: .named("AIChatScroll")).minY
                                        let atBottom = minY < 20 // threshold in points; tweak if needed
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showScrollToBottom = !atBottom && (vm.messages.count > 0 || vm.isStreaming)
                                        }
                                    }
                            }
                            .frame(height: 1)
                            .id(bottomID)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                    }
                    .coordinateSpace(name: "AIChatScroll")
                    .scrollDismissesKeyboard(.interactively)

                    .onChange(of: vm.streamingText) { _, _ in
                        guard shouldAutoScroll else { return }
                        scrollToBottom(proxy)
                    }

                    .onAppear {
                        scrollToBottom(proxy)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if showScrollToBottom {
                            AIScrollToBottomButton {
                                scrollToBottom(proxy)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 90)
                        }
                    }
                }

                // MARK: - Input Area
                inputArea
            }
        }
        .onAppear {
            Task { _ = await voice.requestAuthorization() }
        }
        .navigationTitle("AI Meals")
        .toolbarBackground(AppColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI Meals").fontWeight(.semibold)
                }
                .foregroundColor(AppColor.primary)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { vm.clearChat() } label: {
                    Image(systemName: "trash")
                }

                // ✅ FIXED: regenerate should regenerate last user prompt, not resend AI output
                Button {
                    vm.regenerateLast(groceries: groceryViewModel.items)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan meals from what you have")
                .font(AppFont.subtitle(18))
                .foregroundStyle(AppColor.textPrimary)

            Text("Ask for meal plans, macros, or recipes using your grocery list.")
                .font(AppFont.body(14))
                .foregroundStyle(AppColor.textSecondary)

            VStack(spacing: 10) {
                AIQuickPromptChip(text: "Create meal plan for 2lbs chicken with rice") {
                    vm.sendMessage(
                        "Create meal plan for 2lbs chicken with rice",
                        groceries: groceryViewModel.items
                    )
                }

                AIQuickPromptChip(text: "Make me a quick balanced meal plan for today.") {
                    vm.sendMessage(
                        "Make me a quick balanced meal plan for today.",
                        groceries: groceryViewModel.items
                    )
                }

                AIQuickPromptChip(text: "Suggest 3 high-protein dinners using my groceries.") {
                    vm.sendMessage(
                        "Suggest 3 high-protein dinners using my groceries.",
                        groceries: groceryViewModel.items
                    )
                }
            }
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 10) {

            HStack {
                Spacer()
                Button {
                    Haptic.light()
                    vm.sendMessage(
                        "Make me a quick balanced meal plan for today.",
                        groceries: groceryViewModel.items
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                        Text("Magic meal")
                            .font(AppFont.caption(12))
                    }
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    )
                }
            }

            HStack(spacing: 10) {
                // Mic
                Button {
                    Haptic.light()
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
                        .foregroundColor(voice.isRecording ? .red : AppColor.accent)
                        .padding(4)
                }

                // TextField
                ZStack(alignment: .leading) {
                    if inputText.isEmpty {
                        Text("Ask for a meal plan…")
                            .font(AppFont.body(14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 18)
                    }

                    TextField("", text: $inputText, axis: .vertical)
                        .font(AppFont.body(14))
                        .lineLimit(1...5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

                // Send
                Button {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Haptic.medium()
                    vm.sendMessage(text, groceries: groceryViewModel.items)
                    inputText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(AppColor.accent)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [AppColor.background.opacity(0), AppColor.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Helpers

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        AVSpeechSynthesizer().speak(utterance)
    }

    // MARK: - Grocery Integration

    private func addAssistantMessageToGrocery(_ text: String) {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var extracted: [(name: String, quantity: String)] = []

        for line in lines {
            if line.hasPrefix("- ") || line.hasPrefix("• ") {
                parseLine(String(line.dropFirst(2)), into: &extracted)
                continue
            }

            if let dot = line.firstIndex(of: ".") {
                let prefix = line[..<dot]
                if Int(prefix) != nil {
                    let rest = line[line.index(after: dot)...]
                    parseLine(String(rest), into: &extracted)
                }
            }
        }

        guard !extracted.isEmpty else { return }

        let existing = Set(groceryViewModel.items.map { $0.name.lowercased() })

        for item in extracted {
            guard !existing.contains(item.name.lowercased()) else { continue }
            groceryViewModel.addItem(name: item.name, quantity: item.quantity)
        }

        Haptic.success()
    }

    private func parseLine(_ line: String,
                           into results: inout [(name: String, quantity: String)]) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let parts = trimmed.split(separator: " ")
        guard parts.count >= 2 else {
            results.append((trimmed, ""))
            return
        }

        let last = parts.last!.lowercased()
        let quantityHints = ["g", "kg", "ml", "l", "cup", "cups", "tbsp", "tsp", "x"]

        if quantityHints.contains(where: { last.contains($0) }) {
            let name = parts.dropLast().joined(separator: " ")
            results.append((name, String(parts.last!)))
        } else {
            results.append((trimmed, ""))
        }
    }
}
