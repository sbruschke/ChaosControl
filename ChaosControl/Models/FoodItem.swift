import Foundation
import SwiftData

// MARK: - Saved Food Item (for favorites / recent foods database)

@Model
final class FoodItem {
    var name: String
    var carbsPerServing: Double
    var defaultServingSize: String
    var category: String
    var isFavorite: Bool
    var lastUsed: Date?
    var useCount: Int

    init(
        name: String,
        carbsPerServing: Double,
        defaultServingSize: String = "1 serving",
        category: String = "UNCATEGORIZED",
        isFavorite: Bool = false,
        lastUsed: Date? = nil,
        useCount: Int = 0
    ) {
        self.name = name
        self.carbsPerServing = carbsPerServing
        self.defaultServingSize = defaultServingSize
        self.category = category
        self.isFavorite = isFavorite
        self.lastUsed = lastUsed
        self.useCount = useCount
    }
}
