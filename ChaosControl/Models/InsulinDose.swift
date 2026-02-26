import Foundation
import SwiftData

// MARK: - Dose Type

enum DoseType: String, Codable {
    case meal = "MEAL"
    case correction = "CORRECTION"
    case combined = "COMBINED"
}

// MARK: - Insulin Dose Model

@Model
final class InsulinDose {
    var totalUnits: Double
    var mealUnits: Double
    var correctionUnits: Double
    var iobDeducted: Double
    var doseTypeRawValue: String
    var timestamp: Date
    var glucoseAtTime: Double?
    var carbsForDose: Double?
    var notes: String?

    var doseType: DoseType {
        get { DoseType(rawValue: doseTypeRawValue) ?? .combined }
        set { doseTypeRawValue = newValue.rawValue }
    }

    init(
        totalUnits: Double,
        mealUnits: Double = 0,
        correctionUnits: Double = 0,
        iobDeducted: Double = 0,
        doseType: DoseType = .combined,
        timestamp: Date = .now,
        glucoseAtTime: Double? = nil,
        carbsForDose: Double? = nil,
        notes: String? = nil
    ) {
        self.totalUnits = totalUnits
        self.mealUnits = mealUnits
        self.correctionUnits = correctionUnits
        self.iobDeducted = iobDeducted
        self.doseTypeRawValue = doseType.rawValue
        self.timestamp = timestamp
        self.glucoseAtTime = glucoseAtTime
        self.carbsForDose = carbsForDose
        self.notes = notes
    }
}
