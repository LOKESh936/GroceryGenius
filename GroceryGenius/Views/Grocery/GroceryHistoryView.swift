import SwiftUI

struct GroceryHistoryView: View {

    @EnvironmentObject var vm: GroceryHistoryViewModel
    @EnvironmentObject var groceryVM: GroceryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var renaming: GroceryHistory?
    @State private var previewing: GroceryHistory?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                List {

                    // ⭐ NEW LIST
                    newListRow
                        .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)

                    if vm.history.isEmpty {
                        Text("No history yet")
                            .font(AppFont.body(15))
                            .foregroundStyle(AppColor.textSecondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(vm.history) { history in
                            historyRow(history)
                                .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)

                                // ⬅️ DELETE + DUPLICATE
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                    Button {
                                        Haptic.light()
                                        Task { await vm.duplicate(history) }
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(AppColor.secondary)

                                    Button(role: .destructive) {
                                        Haptic.medium()
                                        Task { await vm.delete(history) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // ➡️ EDIT
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        Haptic.light()
                                        renaming = history
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppColor.primary)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColor.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $vm.sort) {
                            ForEach(GroceryHistoryViewModel.SortOption.allCases) {
                                Text($0.title).tag($0)
                            }
                        }
                        .onChange(of: vm.sort) { oldValue, newValue in
                            vm.setSort(newValue)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .foregroundStyle(AppColor.primary)
                }
            }
            .onAppear { Task { await vm.load() } }
            .sheet(item: $renaming) { RenameHistorySheet(history: $0).environmentObject(vm) }
            .sheet(item: $previewing) {
                GroceryHistoryPreviewSheet(history: $0)
                    .environmentObject(groceryVM)
            }
        }
    }

    // MARK: - New List
    private var newListRow: some View {
        Button {
            Haptic.medium()
            groceryVM.clearAll()
            dismiss()
        } label: {
            GGCard {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColor.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Grocery List")
                            .font(AppFont.subtitle(15))
                        Text("Start fresh")
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - History Row (Preview)
    private func historyRow(_ history: GroceryHistory) -> some View {
        Button {
            previewing = history
        } label: {
            GGCard {
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColor.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(history.title)
                            .font(AppFont.subtitle(15))
                            .lineLimit(1)

                        Text(history.completedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(AppFont.caption(12))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}
