import SwiftUI

struct AIChatsListView: View {

    @EnvironmentObject var vm: AIViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTitle: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {

                    // MARK: - New Chat Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start new chat")
                            .font(AppFont.subtitle(16))
                            .foregroundStyle(AppColor.textPrimary)

                        HStack(spacing: 10) {
                            TextField("Chat title (optional)", text: $newTitle)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(AppColor.cardElevated)
                                .cornerRadius(12)
                                .submitLabel(.done)

                            Button {
                                let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                vm.startNewConversation(
                                    title: title.isEmpty ? "New meal plan" : title
                                )
                                newTitle = ""
                                dismiss()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(AppColor.accent)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    .background(AppColor.cardBackground)
                    .cornerRadius(18)
                    .padding(.horizontal)

                    // MARK: - Conversations List
                    List {
                        if vm.conversations.isEmpty {
                            Text("No conversations yet")
                                .foregroundStyle(AppColor.textSecondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(vm.conversations) { convo in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(convo.title)
                                            .font(AppFont.subtitle(15))
                                            .foregroundStyle(AppColor.textPrimary)

                                        Text(
                                            convo.createdAt.formatted(
                                                date: .abbreviated,
                                                time: .omitted
                                            )
                                        )
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(AppColor.textSecondary)
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.switchConversation(convo)
                                    dismiss()
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.deleteConversation(convo)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
                .padding(.bottom, 20)
            }
            // ✅ THIS is the key line
            .keyboardDismissable()
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }
            }
            .onAppear {
                Task { await vm.loadConversations() }
            }
        }
    }
}
