import SwiftUI

// Testing git push 1
struct AIFoodView: View {
    @StateObject var viewModel = AIViewModel()
    @State private var inputText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                
                
                // MARK: - Messages Scroll
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { msg in
                            MessageBubbleView(msg: msg)
                        }
                    }
                }
                
                // Floating Quick Plan Button
                HStack {
                    Spacer()

                    GlassButton(title: nil, icon: "wand.and.stars") {
                        viewModel.sendMessage("Make me a quick meal plan.")
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 44)   // ← PERFECT HEIGHT ABOVE SEND BAR
                    .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
                }
                .animation(.easeOut(duration: 0.25), value: viewModel.messages.count)


                // MARK: - Input Bar (Perfect iMessage style)
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                        HStack {
                            TextField("Ask for a meal plan…", text: $inputText)
                                .padding(.leading, 16)
                                .padding(.vertical, 10)

                            Button {
                                if !inputText.isEmpty {
                                    viewModel.sendMessage(inputText)
                                    inputText = ""
                                }
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(AppColor.accent)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .frame(height: 48)   // FIX: Proper iMessage height
                }
                .padding(.horizontal)
                .padding(.bottom)

            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("AI Meal Planner")
        }
    }
}

#Preview {
    AIFoodView()
}
