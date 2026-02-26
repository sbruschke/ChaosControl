import Foundation

// MARK: - Insulin Calculator Service

struct InsulinCalculation {
    let mealDose: Double
    let correctionDose: Double
    let iob: Double
    let totalDose: Double
    let currentGlucose: Double
    let targetGlucose: Double
    let carbs: Double
    let carbRatio: Double
    let sensitivityFactor: Double
}

struct InsulinCalculator {

    /// Calculate the recommended insulin dose
    /// - Parameters:
    ///   - currentGlucose: Current blood glucose in mg/dL
    ///   - targetGlucose: Target blood glucose in mg/dL
    ///   - carbs: Grams of carbohydrates to consume
    ///   - carbRatio: Insulin-to-carb ratio (1 unit per X grams)
    ///   - sensitivityFactor: Insulin sensitivity factor (1 unit drops BG by X mg/dL)
    ///   - iob: Current insulin on board in units
    /// - Returns: InsulinCalculation with all components
    static func calculate(
        currentGlucose: Double,
        targetGlucose: Double,
        carbs: Double,
        carbRatio: Double,
        sensitivityFactor: Double,
        iob: Double = 0
    ) -> InsulinCalculation {
        // Meal dose: carbs / ICR
        let mealDose = carbRatio > 0 ? carbs / carbRatio : 0

        // Correction dose: (current - target) / ISF
        let correctionDose: Double
        if sensitivityFactor > 0 && currentGlucose > targetGlucose {
            correctionDose = (currentGlucose - targetGlucose) / sensitivityFactor
        } else {
            correctionDose = 0
        }

        // Total: meal + correction - IOB (never negative)
        let totalDose = max(0, mealDose + correctionDose - iob)

        return InsulinCalculation(
            mealDose: round(mealDose, to: 1),
            correctionDose: round(correctionDose, to: 1),
            iob: round(iob, to: 1),
            totalDose: round(totalDose, to: 1),
            currentGlucose: currentGlucose,
            targetGlucose: targetGlucose,
            carbs: carbs,
            carbRatio: carbRatio,
            sensitivityFactor: sensitivityFactor
        )
    }

    /// Calculate insulin on board (IOB) using a linear decay model
    /// - Parameters:
    ///   - doses: Recent insulin doses
    ///   - actionDuration: Insulin action duration in hours (typically 3-5)
    ///   - at: The time to calculate IOB for
    /// - Returns: Estimated units of insulin still active
    static func calculateIOB(
        doses: [InsulinDose],
        actionDuration: Double = 4.0,
        at date: Date = .now
    ) -> Double {
        let actionSeconds = actionDuration * 3600

        return doses.reduce(0) { total, dose in
            let elapsed = date.timeIntervalSince(dose.timestamp)

            // Skip doses in the future or older than action duration
            guard elapsed >= 0, elapsed < actionSeconds else { return total }

            // Linear decay: remaining fraction = 1 - (elapsed / duration)
            let remaining = 1.0 - (elapsed / actionSeconds)
            return total + dose.totalUnits * remaining
        }
    }

    /// Estimate A1C from average glucose
    /// ADAG formula: A1C = (average_glucose_mg_dl + 46.7) / 28.7
    static func estimateA1C(averageGlucose: Double) -> Double {
        round((averageGlucose + 46.7) / 28.7, to: 1)
    }

    /// Calculate time in range percentage
    static func timeInRange(
        readings: [GlucoseReading],
        low: Double = 70,
        high: Double = 180
    ) -> Double {
        guard !readings.isEmpty else { return 0 }
        let inRange = readings.filter { $0.value >= low && $0.value <= high }.count
        return Double(inRange) / Double(readings.count) * 100
    }

    /// Calculate time in each range category
    static func rangeBreakdown(readings: [GlucoseReading]) -> RangeBreakdown {
        guard !readings.isEmpty else {
            return RangeBreakdown(veryHigh: 0, high: 0, inRange: 0, low: 0, veryLow: 0)
        }

        let total = Double(readings.count)
        let veryHigh = Double(readings.filter { $0.value > 250 }.count) / total * 100
        let high = Double(readings.filter { $0.value > 180 && $0.value <= 250 }.count) / total * 100
        let inRange = Double(readings.filter { $0.value >= 70 && $0.value <= 180 }.count) / total * 100
        let low = Double(readings.filter { $0.value >= 54 && $0.value < 70 }.count) / total * 100
        let veryLow = Double(readings.filter { $0.value < 54 }.count) / total * 100

        return RangeBreakdown(
            veryHigh: round(veryHigh, to: 0),
            high: round(high, to: 0),
            inRange: round(inRange, to: 0),
            low: round(low, to: 0),
            veryLow: round(veryLow, to: 0)
        )
    }

    private static func round(_ value: Double, to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        return (value * multiplier).rounded() / multiplier
    }
}

struct RangeBreakdown {
    let veryHigh: Double
    let high: Double
    let inRange: Double
    let low: Double
    let veryLow: Double
}
