import SwiftUI

struct AIConversationsSheet: View {

    @EnvironmentObject var vm: AIViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 12) {

                    // New chat card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start a new chat")
                            .font(AppFont.subtitle(16))
                            .foregroundStyle(AppColor.textPrimary)

                        HStack(spacing: 10) {
                            TextField("Title (optional)", text: $newTitle)
                                .textInputAutocapitalization(.sentences)
                                .autocorrectionDisabled(false)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.75))
                                .cornerRadius(12)

                            Button {
                                Haptic.medium()
                                let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                vm.startNewConversation(title: title.isEmpty ? "New meal plan" : title)
                                newTitle = ""
                                dismiss()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(AppColor.accent)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                            }
                            .accessibilityLabel("Create new chat")
                        }
                    }
                    .padding(16)
                    .background(AppColor.cardBackground)
                    .cornerRadius(18)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Conversations list
                    List {
                        if vm.conversations.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No conversations yet")
                                    .font(AppFont.subtitle(16))
                                Text("Start a new meal chat to see it here.")
                                    .font(AppFont.body(14))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 8)
                        } else {
                            ForEach(vm.conversations) { convo in
                                Button {
                                    Haptic.light()
                                    vm.switchConversation(convo)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .foregroundStyle(AppColor.primary)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(convo.title)
                                                .font(AppFont.subtitle(15))
                                                .foregroundStyle(AppColor.textPrimary)
                                                .lineLimit(1)

                                            Text(convo.createdAt.formatted(date: .abbreviated, time: .omitted))
                                                .font(AppFont.caption(12))
                                                .foregroundStyle(AppColor.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(AppColor.textSecondary.opacity(0.7))
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.loadConversations() }
                        Haptic.light()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
            .onAppear {
                Task { await vm.loadConversations() }
            }
        }
    }
}
