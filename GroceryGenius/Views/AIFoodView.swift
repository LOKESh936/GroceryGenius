import SwiftUI

struct AIFoodView: View {
    @StateObject private var vm = AIViewModel()
    @StateObject private var voice = VoiceInputManager()

    // Shared grocery list from the app
    @EnvironmentObject var groceryViewModel: GroceryViewModel

    @State private var inputText: String = ""

    // Anchor used for smooth auto-scrolling
    private let bottomID = "BOTTOM_ANCHOR"

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {

                            // Quick prompt suggestions when chat is empty
                            if vm.messages.isEmpty && !vm.isStreaming {
                                VStack(spacing: 12) {
                                    quickPromptBubble(
                                        "Create meal plan for 2lbs chicken with rice"
                                    )
                                    quickPromptBubble(
                                        "Make me a quick meal plan."
                                    )
                                }
                                .padding(.top, 48)
                                .padding(.horizontal, 32)
                            }

                            // Conversation bubbles
                            ForEach(vm.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            // Streaming bubble ("typing" / live text)
                            if vm.isStreaming {
                                if vm.streamingText.isEmpty {
                                    TypingBubbleView()
                                } else {
                                    MessageBubbleView(
                                        message: AIMsg(
                                            text: vm.streamingText,
                                            isUser: false
                                        )
                                    )
                                }
                            }

                            // Invisible anchor at the very bottom
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.top, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    // Auto-scroll when messages count changes
                    .onChange(of: vm.messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    // Auto-scroll as streaming text grows
                    .onChange(of: vm.streamingText) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                }

                // MARK: - Magic button + Input bar
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        magicAIButton
                    }

                    inputBar
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            Task {
                _ = await voice.requestAuthorization()
            }
        }
        .navigationTitle("AI Meals")
        .toolbarBackground(AppColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI Meals")
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColor.primary)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    vm.clearChat()
                } label: {
                    Image(systemName: "trash")
                }

                Button {
                    if let lastPrompt = vm.latestAIText {
                        vm.sendMessage(lastPrompt, groceries: groceryViewModel.items)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    // Quick orange suggestion buttons
    private func quickPromptBubble(_ text: String) -> some View {
        Button {
            vm.sendMessage(text, groceries: groceryViewModel.items)
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(14)
            .background(AppColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }

    // Magic "make me a plan" button
    private var magicAIButton: some View {
        Button {
            vm.sendMessage("Make me a quick balanced meal plan for today.",
                           groceries: groceryViewModel.items)
        } label: {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColor.accent)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15),
                                radius: 6, x: 0, y: 3)
                )
        }
        .accessibilityLabel("Magic AI meal suggestion")
    }

    // Input bar: mic + textfield + send
    private var inputBar: some View {
        HStack(spacing: 10) {
            // Mic
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
                    .foregroundColor(voice.isRecording ? .red : AppColor.accent)
            }

            // Text field
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

            // Send
            Button {
                let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }

                vm.sendMessage(text, groceries: groceryViewModel.items)
                inputText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(AppColor.accent)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
}
