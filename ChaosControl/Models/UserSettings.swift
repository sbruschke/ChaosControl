import Foundation
import SwiftData

// MARK: - User Settings Model

@Model
final class UserSettings {
    /// Insulin to Carb Ratio: 1 unit per X grams of carbs
    var carbRatio: Double

    /// Insulin Sensitivity Factor: 1 unit drops BG by X mg/dL
    var sensitivityFactor: Double

    /// Target blood glucose in mg/dL
    var targetGlucose: Double

    /// Insulin action duration in hours (for IOB calculation)
    var insulinActionDuration: Double

    /// Low glucose threshold in mg/dL
    var lowThreshold: Double

    /// High glucose threshold in mg/dL
    var highThreshold: Double

    /// Whether Dexcom integration is enabled
    var dexcomEnabled: Bool

    /// Dexcom region: "us", "ous", "jp"
    var dexcomRegion: String

    /// Auto-refresh interval for Dexcom data in seconds
    var dexcomRefreshInterval: Double

    /// Preferred unit: "mgdl" or "mmoll"
    var preferredUnit: String

    init(
        carbRatio: Double = 10,
        sensitivityFactor: Double = 40,
        targetGlucose: Double = 120,
        insulinActionDuration: Double = 4,
        lowThreshold: Double = 70,
        highThreshold: Double = 180,
        dexcomEnabled: Bool = false,
        dexcomRegion: String = "us",
        dexcomRefreshInterval: Double = 300,
        preferredUnit: String = "mgdl"
    ) {
        self.carbRatio = carbRatio
        self.sensitivityFactor = sensitivityFactor
        self.targetGlucose = targetGlucose
        self.insulinActionDuration = insulinActionDuration
        self.lowThreshold = lowThreshold
        self.highThreshold = highThreshold
        self.dexcomEnabled = dexcomEnabled
        self.dexcomRegion = dexcomRegion
        self.dexcomRefreshInterval = dexcomRefreshInterval
        self.preferredUnit = preferredUnit
    }
}
