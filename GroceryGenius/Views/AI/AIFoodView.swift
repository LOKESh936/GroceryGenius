import SwiftUI
import AVFoundation

struct AIFoodView: View {

    @EnvironmentObject var vm: AIViewModel
    @EnvironmentObject var groceryViewModel: GroceryViewModel
    @StateObject private var voice = VoiceInputManager()

    @State private var inputText: String = ""
    @State private var showChatsSheet = false

    @State private var userScrolledUp = false
    private let bottomID = "BOTTOM_ANCHOR"

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            if vm.messages.isEmpty && !vm.isStreaming {
                                emptyState
                                    .padding(.top, 24)
                                    .padding(.horizontal, 20)
                            }

                            ForEach(vm.messages) { msg in
                                AIMessageBubbleView(
                                    message: msg,
                                    onCopy: { UIPasteboard.general.string = msg.text },
                                    onSpeak: { speak(msg.text) },
                                    onAddItems: { addAssistantMessageToGrocery(msg.text) }
                                )
                                .id(msg.id)
                                .padding(.horizontal, 16)
                            }

                            if vm.isStreaming {
                                if vm.streamingText.isEmpty {
                                    AITypingIndicatorView()
                                        .padding(.horizontal, 16)
                                } else {
                                    AIMessageBubbleView(
                                        message: AIMsg(text: vm.streamingText, isUser: false),
                                        isStreaming: true,
                                        onCopy: { UIPasteboard.general.string = vm.streamingText },
                                        onSpeak: { speak(vm.streamingText) },
                                        onAddItems: { addAssistantMessageToGrocery(vm.streamingText) }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }

                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.bottom, 10)
                    }
                    // ✅ interactive keyboard dismissal (modern iOS feel)
                    .scrollDismissesKeyboard(.interactively)
                    // ✅ Tap to dismiss keyboard without breaking scroll
                    .dismissKeyboardOnTap()
                    // ✅ Detect user scroll
                    .simultaneousGesture(
                        DragGesture().onChanged { _ in userScrolledUp = true }
                    )
                    .onChange(of: vm.messages.count) { _, _ in
                        if !userScrolledUp { scrollToBottom(proxy) }
                    }
                    .onChange(of: vm.streamingText) { _, _ in
                        if !userScrolledUp { scrollToBottom(proxy) }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if userScrolledUp {
                            scrollDownButton(proxy)
                        }
                    }
                }

                inputArea
            }
        }
        .onAppear { Task { _ = await voice.requestAuthorization() } }
        .onReceive(NotificationCenter.default.publisher(for: .openAIChats)) { _ in
            showChatsSheet = true
        }
        .sheet(isPresented: $showChatsSheet) {
            AIConversationsSheet()
                .environmentObject(vm)
        }
        .alert(
            "Upgrade to Pro",
            isPresented: $vm.showUpgradePrompt
        ) {
            Button("Upgrade") {
                // future: open paywall
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Free users get 5 AI responses per day. Upgrade to Pro for unlimited access.")
        }

    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Plan meals from what you have")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)

            Text("Ask for meal plans, recipes, or macros.")
                .font(.system(size: 14))
                .foregroundStyle(AppColor.textSecondary)

            VStack(spacing: 10) {
                quickPrompt("Create a meal plan using my groceries")
                quickPrompt("Suggest high-protein meals")
                quickPrompt("Make a quick balanced meal plan for today")
            }
        }
    }

    private func quickPrompt(_ text: String) -> some View {
        Button {
            hideKeyboard()
            vm.sendMessage(text, groceries: groceryViewModel.items)
        } label: {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColor.cardBackground)
                )
        }
        .buttonStyle(.plain)
    }

    private var inputArea: some View {
        HStack(spacing: 10) {

            Button {
                voice.isRecording ? voice.stopRecording() : voice.startRecording { inputText = $0 }
            } label: {
                Image(systemName: voice.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(voice.isRecording ? .red : AppColor.accent)
            }

            TextField("Ask for a meal plan…", text: $inputText, axis: .vertical)
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .submitLabel(.send)
                .onSubmit {
                    send()
                }

            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(AppColor.accent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        hideKeyboard()
        vm.sendMessage(text, groceries: groceryViewModel.items)
        inputText = ""
        userScrolledUp = false
    }

    @ViewBuilder
    private func scrollDownButton(_ proxy: ScrollViewProxy) -> some View {
        Button {
            userScrolledUp = false
            scrollToBottom(proxy)
        } label: {
            Image(systemName: "arrow.down")
                .foregroundColor(.white)
                .padding(14)
                .background(AppColor.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 90)
        .transition(.scale.combined(with: .opacity))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.5
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        AVSpeechSynthesizer().speak(u)
    }

    private func addAssistantMessageToGrocery(_ text: String) {
        groceryViewModel.addItem(name: text, quantity: "")
    }
}
