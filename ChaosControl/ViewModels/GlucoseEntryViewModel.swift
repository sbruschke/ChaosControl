import Foundation
import SwiftData

@Observable
final class GlucoseEntryViewModel {
    var glucoseValue: String = ""
    var selectedContext: ReadingContext? = nil
    var notes: String = ""
    var timestamp: Date = .now
    var isSaving = false

    var glucoseDouble: Double? {
        Double(glucoseValue)
    }

    var isValid: Bool {
        guard let value = glucoseDouble else { return false }
        return value >= 20 && value <= 600
    }

    var rangeStatus: String {
        guard let value = glucoseDouble else { return "" }
        return ChaosTheme.glucoseStatus(for: value)
    }

    var rangeColor: some Any {
        guard let value = glucoseDouble else { return ChaosTheme.faded }
        return ChaosTheme.glucoseColor(for: value)
    }

    /// Position on the range bar (0-1)
    var rangePosition: Double {
        guard let value = glucoseDouble else { return 0.5 }
        // Range bar goes from 40 to 300
        return min(1, max(0, (value - 40) / 260))
    }

    func save(modelContext: ModelContext) -> GlucoseReading? {
        guard let value = glucoseDouble, isValid else { return nil }
        isSaving = true

        let reading = GlucoseReading(
            value: value,
            timestamp: timestamp,
            context: selectedContext,
            source: .manual,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(reading)

        isSaving = false
        return reading
    }

    func reset() {
        glucoseValue = ""
        selectedContext = nil
        notes = ""
        timestamp = .now
    }
}
