import Foundation
import SwiftData
import Observation

@Observable
final class MealLogViewModel {
    var selectedMealType: MealType = .midday
    var currentItems: [MealItem] = []
    var searchText: String = ""
    var isSaving = false
    var mealName: String = ""

    // New item entry
    var newItemName: String = ""
    var newItemCarbs: Double = 0
    var newItemServing: String = ""
    var newItemCategory: String = "UNCATEGORIZED"
    var showingAddItem = false
    var showingCategoryManagement = false

    // Category filter
    var selectedCategory: String? = nil
    var allCategories: [String] = []

    var totalCarbs: Double { currentItems.reduce(0) { $0 + $1.carbs } }

    func addItem() {
        guard !newItemName.isEmpty else { return }
        let item = MealItem(
            name: newItemName.uppercased(),
            carbs: newItemCarbs,
            servingSize: newItemServing
        )
        currentItems.append(item)
        clearNewItem()
    }

    func addFromFavorite(_ food: FoodItem, modelContext: ModelContext) {
        let item = MealItem(
            name: food.name,
            carbs: food.carbsPerServing,
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
            name: mealName.isEmpty ? nil : mealName.uppercased(),
            items: currentItems
        )

        modelContext.insert(meal)

        // Save new foods to favorites database
        for item in currentItems {
            let itemName = item.name
            let predicate = #Predicate<FoodItem> { $0.name == itemName }
            let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
            if (try? modelContext.fetch(descriptor))?.isEmpty ?? true {
                let foodItem = FoodItem(
                    name: item.name,
                    carbsPerServing: item.carbs,
                    defaultServingSize: item.servingSize,
                    category: newItemCategory,
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

    func loadFoodsByCategory(modelContext: ModelContext, category: String) -> [FoodItem] {
        let predicate = #Predicate<FoodItem> { $0.category == category }
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadCategories(modelContext: ModelContext) {
        var categories = DefaultFoodCategory.defaultNames
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            categories.append(contentsOf: settings.customCategories ?? [])
        }
        allCategories = categories
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
        mealName = ""
        selectedCategory = nil
    }

    private func clearNewItem() {
        newItemName = ""
        newItemCarbs = 0
        newItemServing = ""
        newItemCategory = "UNCATEGORIZED"
        showingAddItem = false
    }
}
