import Foundation
import SwiftData
import Observation

/// Plain struct for in-progress meal items (NOT a SwiftData @Model).
/// MealItem @Model objects are only created at save time to avoid SwiftData lifecycle crashes.
struct TempMealItem: Identifiable {
    let id = UUID()
    var name: String
    var carbs: Double
    var servingSize: String
}

@Observable
final class MealLogViewModel {
    var selectedMealType: MealType = .midday
    var currentItems: [TempMealItem] = []
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
        let item = TempMealItem(
            name: newItemName.uppercased(),
            carbs: newItemCarbs,
            servingSize: newItemServing
        )
        currentItems.append(item)
        clearNewItem()
    }

    func addFromFavorite(_ food: FoodItem, modelContext: ModelContext) {
        let item = TempMealItem(
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

        appLog("saveMeal: \(currentItems.count) items, type=\(selectedMealType.rawValue)", category: "DATA")

        // Create meal and insert into context first
        let meal = Meal(
            mealType: selectedMealType,
            name: mealName.isEmpty ? nil : mealName.uppercased(),
            items: []
        )
        modelContext.insert(meal)

        // Create real MealItem @Model objects from TempMealItems and attach to meal
        var savedItems: [MealItem] = []
        for temp in currentItems {
            let mealItem = MealItem(
                name: temp.name,
                carbs: temp.carbs,
                servingSize: temp.servingSize
            )
            modelContext.insert(mealItem)
            mealItem.meal = meal
            savedItems.append(mealItem)
        }
        meal.items = savedItems

        appLog("saveMeal: meal inserted with \(meal.items.count) items", category: "DATA")

        // Save new foods to favorites database
        for temp in currentItems {
            let itemName = temp.name
            let predicate = #Predicate<FoodItem> { $0.name == itemName }
            let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
            if (try? modelContext.fetch(descriptor))?.isEmpty ?? true {
                let foodItem = FoodItem(
                    name: temp.name,
                    carbsPerServing: temp.carbs,
                    defaultServingSize: temp.servingSize,
                    category: newItemCategory,
                    lastUsed: .now,
                    useCount: 1
                )
                modelContext.insert(foodItem)
                appLog("saveMeal: new food saved to favorites: \(temp.name)", category: "DATA")
            }
        }

        // Export to human-readable Databases folder
        for temp in currentItems {
            DatabaseExporter.shared.exportFood(
                name: temp.name,
                carbs: temp.carbs,
                serving: temp.servingSize,
                category: newItemCategory
            )
        }
        DatabaseExporter.shared.exportMealToHistory(
            items: currentItems.map { (name: $0.name, carbs: $0.carbs) },
            mealType: selectedMealType.rawValue
        )

        // Explicit save to catch any errors
        do {
            try modelContext.save()
            appLog("saveMeal: context saved successfully", category: "DATA")
        } catch {
            appLog("saveMeal: context save ERROR — \(error.localizedDescription)", category: "ERROR")
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
