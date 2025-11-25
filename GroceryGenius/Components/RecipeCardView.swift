import SwiftUI

struct RecipeCardView: View {
    let text: String
    
    private var title: String {
        if let firstLine = text.split(separator: "\n").first {
            return String(firstLine).replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
        }
        return "AI Meal Plan"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.4))
            
            ScrollView {
                MarkdownText(text: text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.27, green: 0.46, blue: 0.23),
                    Color(red: 0.2, green: 0.35, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}
