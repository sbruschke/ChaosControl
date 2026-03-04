import Foundation
import SwiftData
import Observation

enum TimeRange: String, CaseIterable {
    case day = "24H"
    case week = "7D"
    case twoWeeks = "14D"
    case month = "30D"
    case threeMonths = "90D"

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .threeMonths: return 90
        }
    }

    var minutes: Int {
        days * 1440
    }
}

struct DailyAverage: Identifiable {
    let id = UUID()
    let date: Date
    let average: Double
    let high: Double
    let low: Double
    let readingCount: Int
}

@Observable
final class TrendsViewModel {
    var selectedRange: TimeRange = .week
    var readings: [GlucoseReading] = []
    var dailyAverages: [DailyAverage] = []
    var rangeBreakdown = RangeBreakdown(veryHigh: 0, high: 0, inRange: 0, low: 0, veryLow: 0)
    var averageGlucose: Double = 0
    var highGlucose: Double = 0
    var lowGlucose: Double = 0
    var standardDeviation: Double = 0
    var estimatedA1C: Double = 0
    var timeInRangePercent: Double = 0
    var isLoading = false

    var cutoffDate: Date {
        Date.now.addingTimeInterval(-Double(selectedRange.days) * 86400)
    }

    func loadData(modelContext: ModelContext) {
        isLoading = true

        let cutoff = cutoffDate
        let predicate = #Predicate<GlucoseReading> { $0.timestamp >= cutoff }
        let descriptor = FetchDescriptor<GlucoseReading>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        readings = (try? modelContext.fetch(descriptor)) ?? []
        calculateStats()
        calculateDailyAverages()
        isLoading = false
    }

    private func calculateStats() {
        guard !readings.isEmpty else {
            averageGlucose = 0
            highGlucose = 0
            lowGlucose = 0
            standardDeviation = 0
            estimatedA1C = 0
            timeInRangePercent = 0
            return
        }

        let values = readings.map(\.value)
        averageGlucose = values.reduce(0, +) / Double(values.count)
        highGlucose = values.max() ?? 0
        lowGlucose = values.min() ?? 0

        // Standard deviation
        let mean = averageGlucose
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        standardDeviation = sqrt(squaredDiffs.reduce(0, +) / Double(values.count))

        estimatedA1C = InsulinCalculator.estimateA1C(averageGlucose: averageGlucose)
        timeInRangePercent = InsulinCalculator.timeInRange(readings: readings)
        rangeBreakdown = InsulinCalculator.rangeBreakdown(readings: readings)
    }

    private func calculateDailyAverages() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: readings) { reading in
            calendar.startOfDay(for: reading.timestamp)
        }

        dailyAverages = grouped.map { date, dayReadings in
            let values = dayReadings.map(\.value)
            let avg = values.reduce(0, +) / Double(values.count)
            let high = values.max() ?? 0
            let low = values.min() ?? 0
            return DailyAverage(
                date: date,
                average: avg,
                high: high,
                low: low,
                readingCount: dayReadings.count
            )
        }
        .sorted { $0.date > $1.date }
    }
}
