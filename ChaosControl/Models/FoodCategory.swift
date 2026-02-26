import Foundation

// MARK: - Default Food Categories

enum DefaultFoodCategory: String, CaseIterable {
    case meats = "MEATS"
    case drinks = "DRINKS"
    case desserts = "DESSERTS"
    case fruits = "FRUITS"
    case vegetables = "VEGETABLES"
    case grains = "GRAINS"
    case dairy = "DAIRY"
    case snacks = "SNACKS"
    case uncategorized = "UNCATEGORIZED"

    static var defaultNames: [String] {
        allCases.map(\.rawValue)
    }
}
