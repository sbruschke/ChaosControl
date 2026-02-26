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
    var protein: Double
    var fat: Double
    var fiber: Double
    var calories: Double
    var servingSize: String
    var meal: Meal?

    init(
        name: String,
        carbs: Double,
        protein: Double = 0,
        fat: Double = 0,
        fiber: Double = 0,
        calories: Double = 0,
        servingSize: String = ""
    ) {
        self.name = name
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.calories = calories
        self.servingSize = servingSize
    }
}

// MARK: - Meal Model

@Model
final class Meal {
    var timestamp: Date
    var mealTypeRawValue: String
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

    var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }

    var totalFat: Double {
        items.reduce(0) { $0 + $1.fat }
    }

    var totalFiber: Double {
        items.reduce(0) { $0 + $1.fiber }
    }

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    init(
        timestamp: Date = .now,
        mealType: MealType = .snack,
        items: [MealItem] = [],
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.mealTypeRawValue = mealType.rawValue
        self.items = items
        self.notes = notes
    }
}
