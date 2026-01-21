enum RecipeFilter: String, CaseIterable, Identifiable, Hashable {
    case highProtein
    case quick
    case breakfast
    case vegetarian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .highProtein: return "High Protein"
        case .quick: return "Quick"
        case .breakfast: return "Breakfast"
        case .vegetarian: return "Veg"
        }
    }

    var systemImage: String {
        switch self {
        case .highProtein: return "bolt.fill"
        case .quick: return "timer"
        case .breakfast: return "sunrise.fill"
        case .vegetarian: return "leaf.fill"
        }
    }
}
