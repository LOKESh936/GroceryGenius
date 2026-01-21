import Foundation

struct RecipeUIModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let createdAt: Date
    let tags: [RecipeFilter]

    static let sample: [RecipeUIModel] = [
        .init(
            id: UUID().uuidString,
            title: "Chicken Rice Bowl",
            subtitle: "20 min • high protein",
            createdAt: Date().addingTimeInterval(-86_000),
            tags: [.highProtein]
        ),
        .init(
            id: UUID().uuidString,
            title: "Paneer Wrap",
            subtitle: "15 min • quick",
            createdAt: Date().addingTimeInterval(-200_000),
            tags: [.quick, .vegetarian]
        ),
        .init(
            id: UUID().uuidString,
            title: "Oats + Banana",
            subtitle: "5 min • breakfast",
            createdAt: Date().addingTimeInterval(-400_000),
            tags: [.breakfast, .quick, .vegetarian]
        )
    ]
}
