import Foundation
import SwiftData

// MARK: - Saved Food Item (for favorites / recent foods database)

@Model
final class FoodItem {
    var name: String
    var carbsPerServing: Double
    var proteinPerServing: Double
    var fatPerServing: Double
    var fiberPerServing: Double
    var caloriesPerServing: Double
    var defaultServingSize: String
    var category: String?
    var isFavorite: Bool
    var lastUsed: Date?
    var useCount: Int

    init(
        name: String,
        carbsPerServing: Double,
        proteinPerServing: Double = 0,
        fatPerServing: Double = 0,
        fiberPerServing: Double = 0,
        caloriesPerServing: Double = 0,
        defaultServingSize: String = "1 serving",
        category: String? = nil,
        isFavorite: Bool = false,
        lastUsed: Date? = nil,
        useCount: Int = 0
    ) {
        self.name = name
        self.carbsPerServing = carbsPerServing
        self.proteinPerServing = proteinPerServing
        self.fatPerServing = fatPerServing
        self.fiberPerServing = fiberPerServing
        self.caloriesPerServing = caloriesPerServing
        self.defaultServingSize = defaultServingSize
        self.category = category
        self.isFavorite = isFavorite
        self.lastUsed = lastUsed
        self.useCount = useCount
    }
}
