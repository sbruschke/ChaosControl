import Foundation
import SwiftData

// MARK: - Meal Type

enum MealType: String, Codable, CaseIterable {
    case fasting = "FASTING"
    case morning = "MORNING"
    case midday = "MIDDAY"
    case evening = "EVENING"
    case snack = "SNACK"
}

// MARK: - Meal Item (food entry within a meal)

@Model
final class MealItem {
    var name: String
    var carbs: Double
    var servingSize: String
    var meal: Meal?

    init(
        name: String,
        carbs: Double,
        servingSize: String = ""
    ) {
        self.name = name
        self.carbs = carbs
        self.servingSize = servingSize
    }
}

// MARK: - Meal Model

@Model
final class Meal {
    var timestamp: Date
    var mealTypeRawValue: String
    var name: String?
    @Relationship(deleteRule: .cascade, inverse: \MealItem.meal)
    var items: [MealItem]
    var notes: String?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRawValue) ?? .snack }
        set { mealTypeRawValue = newValue.rawValue }
    }

    var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbs }
    }

    init(
        timestamp: Date = .now,
        mealType: MealType = .snack,
        name: String? = nil,
        items: [MealItem] = [],
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.mealTypeRawValue = mealType.rawValue
        self.name = name
        self.items = items
        self.notes = notes
    }
}
