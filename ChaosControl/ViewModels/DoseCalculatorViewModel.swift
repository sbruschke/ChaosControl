import Foundation
import SwiftData
import Observation

@Observable
final class DoseCalculatorViewModel {
    var currentGlucose: Double = 0
    var targetGlucose: Double = 120
    var carbIntake: Double = 0
    var carbRatio: Double = 10
    var sensitivityFactor: Double = 40
    var insulinOnBoard: Double = 0

    var calculation: InsulinCalculation?
    var isSaving = false

    // Food search
    var foodSearchText: String = ""
    var searchResults: [FoodItem] = []
    var recentFoods: [FoodItem] = []
    var showingFoodSearch = false

    func calculate() {
        calculation = InsulinCalculator.calculate(
            currentGlucose: currentGlucose,
            targetGlucose: targetGlucose,
            carbs: carbIntake,
            carbRatio: carbRatio,
            sensitivityFactor: sensitivityFactor,
            iob: insulinOnBoard
        )
    }

    func loadSettings(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            carbRatio = settings.carbRatio
            sensitivityFactor = settings.sensitivityFactor
            targetGlucose = settings.targetGlucose
            appLog("loadSettings: ICR=\(carbRatio), ISF=\(sensitivityFactor), target=\(targetGlucose)", category: "DATA")
        } else {
            appLog("loadSettings: no UserSettings found, using defaults", category: "WARN")
        }

        // Calculate current IOB
        let fourHoursAgo = Date.now.addingTimeInterval(-4 * 3600)
        let dosePredicate = #Predicate<InsulinDose> { $0.timestamp >= fourHoursAgo }
        let doseDescriptor = FetchDescriptor<InsulinDose>(predicate: dosePredicate)
        if let doses = try? modelContext.fetch(doseDescriptor) {
            insulinOnBoard = InsulinCalculator.calculateIOB(doses: doses)
        }

        // Auto-populate latest glucose reading
        if currentGlucose == 0 {
            let readingDescriptor = FetchDescriptor<GlucoseReading>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let latest = try? modelContext.fetch(readingDescriptor).first {
                currentGlucose = latest.value
            }
        }

        // Load recent foods
        loadRecentFoods(modelContext: modelContext)
    }

    func searchFoods(modelContext: ModelContext) {
        guard !foodSearchText.isEmpty else {
            searchResults = []
            return
        }
        let query = foodSearchText.uppercased()
        let predicate = #Predicate<FoodItem> { $0.name.contains(query) }
        var descriptor = FetchDescriptor<FoodItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        searchResults = (try? modelContext.fetch(descriptor)) ?? []
    }

    func loadRecentFoods(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        descriptor.fetchLimit = 5
        recentFoods = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addFoodCarbs(_ food: FoodItem) {
        carbIntake += food.carbsPerServing
        foodSearchText = ""
        searchResults = []
    }

    func loadFromReading(_ reading: GlucoseReading?) {
        if let reading {
            currentGlucose = reading.value
        }
    }

    func saveDose(modelContext: ModelContext) -> InsulinDose? {
        guard let calc = calculation, calc.totalDose > 0 else { return nil }
        isSaving = true

        let doseType: DoseType
        if calc.mealDose > 0 && calc.correctionDose > 0 {
            doseType = .combined
        } else if calc.mealDose > 0 {
            doseType = .meal
        } else {
            doseType = .correction
        }

        let dose = InsulinDose(
            totalUnits: calc.totalDose,
            mealUnits: calc.mealDose,
            correctionUnits: calc.correctionDose,
            iobDeducted: calc.iob,
            doseType: doseType,
            glucoseAtTime: currentGlucose,
            carbsForDose: carbIntake
        )

        modelContext.insert(dose)
        isSaving = false
        return dose
    }

    func reset() {
        currentGlucose = 0
        carbIntake = 0
        calculation = nil
    }
}
