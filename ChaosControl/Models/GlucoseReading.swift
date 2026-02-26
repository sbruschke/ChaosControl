import Foundation
import SwiftData

// MARK: - Trend Direction

enum TrendDirection: Int, Codable, CaseIterable {
    case none = 0
    case doubleUp = 1
    case singleUp = 2
    case fortyFiveUp = 3
    case flat = 4
    case fortyFiveDown = 5
    case singleDown = 6
    case doubleDown = 7
    case notComputable = 8
    case rateOutOfRange = 9

    var arrow: String {
        switch self {
        case .none: return ""
        case .doubleUp: return "\u{2191}\u{2191}"
        case .singleUp: return "\u{2191}"
        case .fortyFiveUp: return "\u{2197}"
        case .flat: return "\u{2192}"
        case .fortyFiveDown: return "\u{2198}"
        case .singleDown: return "\u{2193}"
        case .doubleDown: return "\u{2193}\u{2193}"
        case .notComputable: return "?"
        case .rateOutOfRange: return "-"
        }
    }

    var description: String {
        switch self {
        case .none: return "NONE"
        case .doubleUp: return "RISING QUICKLY"
        case .singleUp: return "RISING"
        case .fortyFiveUp: return "RISING SLIGHTLY"
        case .flat: return "STABLE"
        case .fortyFiveDown: return "FALLING SLIGHTLY"
        case .singleDown: return "FALLING"
        case .doubleDown: return "FALLING QUICKLY"
        case .notComputable: return "UNKNOWN"
        case .rateOutOfRange: return "UNAVAILABLE"
        }
    }

    /// Initialize from Dexcom Share API trend string
    init(dexcomString: String) {
        switch dexcomString {
        case "None": self = .none
        case "DoubleUp": self = .doubleUp
        case "SingleUp": self = .singleUp
        case "FortyFiveUp": self = .fortyFiveUp
        case "Flat": self = .flat
        case "FortyFiveDown": self = .fortyFiveDown
        case "SingleDown": self = .singleDown
        case "DoubleDown": self = .doubleDown
        case "NotComputable": self = .notComputable
        case "RateOutOfRange": self = .rateOutOfRange
        default: self = .none
        }
    }
}

// MARK: - Reading Context

enum ReadingContext: String, Codable, CaseIterable {
    case fasting = "FASTING"
    case preMeal = "PRE-MEAL"
    case postMeal = "POST-MEAL"
    case bedtime = "BEDTIME"
    case exercise = "EXERCISE"
    case other = "OTHER"
}

// MARK: - Reading Source

enum ReadingSource: String, Codable {
    case manual = "MANUAL"
    case dexcom = "DEXCOM"
}

// MARK: - Glucose Reading Model

@Model
final class GlucoseReading {
    var value: Double
    var trendRawValue: Int
    var timestamp: Date
    var contextRawValue: String?
    var sourceRawValue: String
    var notes: String?

    var trend: TrendDirection {
        get { TrendDirection(rawValue: trendRawValue) ?? .none }
        set { trendRawValue = newValue.rawValue }
    }

    var context: ReadingContext? {
        get { contextRawValue.flatMap { ReadingContext(rawValue: $0) } }
        set { contextRawValue = newValue?.rawValue }
    }

    var source: ReadingSource {
        get { ReadingSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    /// mg/dL value as integer
    var mgDL: Int { Int(value) }

    /// mmol/L conversion
    var mmolL: Double { (value * 0.0555 * 10).rounded() / 10 }

    init(
        value: Double,
        trend: TrendDirection = .flat,
        timestamp: Date = .now,
        context: ReadingContext? = nil,
        source: ReadingSource = .manual,
        notes: String? = nil
    ) {
        self.value = value
        self.trendRawValue = trend.rawValue
        self.timestamp = timestamp
        self.contextRawValue = context?.rawValue
        self.sourceRawValue = source.rawValue
        self.notes = notes
    }
}
