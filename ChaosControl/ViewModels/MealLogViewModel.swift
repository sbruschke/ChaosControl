import Foundation
import SwiftData

@Observable
final class MealLogViewModel {
    var selectedMealType: MealType = .midday
    var currentItems: [MealItem] = []
    var searchText: String = ""
    var isSaving = false

    // New item entry
    var newItemName: String = ""
    var newItemCarbs: Double = 0
    var newItemProtein: Double = 0
    var newItemFat: Double = 0
    var newItemFiber: Double = 0
    var newItemCalories: Double = 0
    var newItemServing: String = ""
    var showingAddItem = false

    var totalCarbs: Double { currentItems.reduce(0) { $0 + $1.carbs } }
    var totalProtein: Double { currentItems.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { currentItems.reduce(0) { $0 + $1.fat } }
    var totalFiber: Double { currentItems.reduce(0) { $0 + $1.fiber } }
    var totalCalories: Double { currentItems.reduce(0) { $0 + $1.calories } }

    func addItem() {
        guard !newItemName.isEmpty else { return }
        let item = MealItem(
            name: newItemName.uppercased(),
            carbs: newItemCarbs,
            protein: newItemProtein,
            fat: newItemFat,
            fiber: newItemFiber,
            calories: newItemCalories,
            servingSize: newItemServing
        )
        currentItems.append(item)
        clearNewItem()
    }

    func addFromFavorite(_ food: FoodItem, modelContext: ModelContext) {
        let item = MealItem(
            name: food.name,
            carbs: food.carbsPerServing,
            protein: food.proteinPerServing,
            fat: food.fatPerServing,
            fiber: food.fiberPerServing,
            calories: food.caloriesPerServing,
            servingSize: food.defaultServingSize
        )
        currentItems.append(item)

        // Update food's last used timestamp
        food.lastUsed = .now
        food.useCount += 1
    }

    func removeItem(at offsets: IndexSet) {
        currentItems.remove(atOffsets: offsets)
    }

    func saveMeal(modelContext: ModelContext) -> Meal? {
        guard !currentItems.isEmpty else { return nil }
        isSaving = true

        let meal = Meal(
            mealType: selectedMealType,
            items: currentItems
        )

        modelContext.insert(meal)

        // Save new foods to favorites database
        for item in currentItems {
            let predicate = #Predicate<FoodItem> { $0.name == item.name }
            let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
            if (try? modelContext.fetch(descriptor))?.isEmpty ?? true {
                let foodItem = FoodItem(
                    name: item.name,
                    carbsPerServing: item.carbs,
                    proteinPerServing: item.protein,
                    fatPerServing: item.fat,
                    fiberPerServing: item.fiber,
                    caloriesPerServing: item.calories,
                    defaultServingSize: item.servingSize,
                    lastUsed: .now,
                    useCount: 1
                )
                modelContext.insert(foodItem)
            }
        }

        isSaving = false
        return meal
    }

    func loadRecentFoods(modelContext: ModelContext) -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadFavoriteFoods(modelContext: ModelContext) -> [FoodItem] {
        let predicate = #Predicate<FoodItem> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func reset() {
        currentItems = []
        selectedMealType = .midday
        searchText = ""
    }

    private func clearNewItem() {
        newItemName = ""
        newItemCarbs = 0
        newItemProtein = 0
        newItemFat = 0
        newItemFiber = 0
        newItemCalories = 0
        newItemServing = ""
        showingAddItem = false
    }
}
