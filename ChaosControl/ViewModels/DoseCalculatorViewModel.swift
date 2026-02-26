import Foundation
import SwiftData

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
        }

        // Calculate current IOB
        let fourHoursAgo = Date.now.addingTimeInterval(-4 * 3600)
        let dosePredicate = #Predicate<InsulinDose> { $0.timestamp >= fourHoursAgo }
        let doseDescriptor = FetchDescriptor<InsulinDose>(predicate: dosePredicate)
        if let doses = try? modelContext.fetch(doseDescriptor) {
            insulinOnBoard = InsulinCalculator.calculateIOB(doses: doses)
        }
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
