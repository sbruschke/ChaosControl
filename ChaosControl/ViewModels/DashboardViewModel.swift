import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    var currentReading: GlucoseReading?
    var recentReadings: [GlucoseReading] = []
    var activeInsulin: Double = 0
    var carbsToday: Double = 0
    var lastMealTime: Date?
    var timeInRange: Double = 0
    var isLoading = false
    var errorMessage: String?
    var dexcomConnected = false

    private let dexcomService = DexcomShareService(region: .us)
    private var refreshTask: Task<Void, Never>?

    var lastMealTimeString: String {
        guard let lastMealTime else { return "--" }
        let interval = Date.now.timeIntervalSince(lastMealTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var statusText: String {
        guard let reading = currentReading else { return "NO DATA" }
        let rangeStatus = ChaosTheme.glucoseStatus(for: reading.value)
        return "\(rangeStatus) // \(reading.trend.description)"
    }

    func loadData(modelContext: ModelContext) {
        loadLocalData(modelContext: modelContext)
    }

    func connectDexcom(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await dexcomService.authenticate(username: username, password: password)
            try KeychainService.saveUsername(username)
            try KeychainService.savePassword(password)
            dexcomConnected = true
            await refreshDexcomData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshDexcomData(modelContext: ModelContext? = nil) async {
        guard await dexcomService.isAuthenticated else { return }
        isLoading = true
        do {
            let dtos = try await dexcomService.getGlucoseReadings(minutes: 1440, maxCount: 288)
            // Convert DTOs to GlucoseReading objects
            let readings = dtos.map {
                GlucoseReading(value: $0.value, trend: $0.trend, timestamp: $0.timestamp, source: .dexcom)
            }
            if let latest = readings.first {
                currentReading = latest
            }
            recentReadings = Array(readings.prefix(12))
            timeInRange = InsulinCalculator.timeInRange(readings: readings)
            dexcomConnected = true

            // Persist to SwiftData if modelContext provided (dedup by timestamp + source)
            if let context = modelContext {
                for reading in readings {
                    let ts = reading.timestamp
                    let predicate = #Predicate<GlucoseReading> { $0.timestamp == ts && $0.sourceRawValue == "DEXCOM" }
                    let descriptor = FetchDescriptor<GlucoseReading>(predicate: predicate)
                    if (try? context.fetch(descriptor))?.isEmpty ?? true {
                        context.insert(reading)
                    }
                }
                try? context.save()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func disconnectDexcom() {
        KeychainService.clearAll()
        dexcomConnected = false
        currentReading = nil
        recentReadings = []
        errorMessage = nil
    }

    func startAutoRefresh(modelContext: ModelContext) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { break }
                await self?.refreshDexcomData(modelContext: modelContext)
                self?.loadLocalData(modelContext: modelContext)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func tryAutoConnect(modelContext: ModelContext) async {
        guard KeychainService.hasCredentials else {
            appLog("tryAutoConnect: no credentials stored", category: "DATA")
            return
        }
        do {
            let username = try KeychainService.getUsername()
            appLog("tryAutoConnect: attempting Dexcom auth for \(username)", category: "DATA")
            let password = try KeychainService.getPassword()
            try await dexcomService.authenticate(username: username, password: password)
            dexcomConnected = true
            appLog("tryAutoConnect: authenticated, fetching readings", category: "DATA")
            await refreshDexcomData(modelContext: modelContext)
            loadLocalData(modelContext: modelContext)
        } catch {
            appLog("tryAutoConnect: failed — \(error.localizedDescription)", category: "WARN")
        }
    }

    // MARK: - Private

    private func loadLocalData(modelContext: ModelContext) {
        // Load today's meals for carb count
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let mealPredicate = #Predicate<Meal> { $0.timestamp >= startOfDay }
        let mealDescriptor = FetchDescriptor<Meal>(
            predicate: mealPredicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let meals = try? modelContext.fetch(mealDescriptor) {
            carbsToday = meals.reduce(0) { $0 + $1.totalCarbs }
            lastMealTime = meals.first?.timestamp
        }

        // Load recent doses for IOB
        let fourHoursAgo = Date.now.addingTimeInterval(-4 * 3600)
        let dosePredicate = #Predicate<InsulinDose> { $0.timestamp >= fourHoursAgo }
        let doseDescriptor = FetchDescriptor<InsulinDose>(predicate: dosePredicate)

        if let doses = try? modelContext.fetch(doseDescriptor) {
            activeInsulin = InsulinCalculator.calculateIOB(doses: doses)
        }

        // Load local readings (always — so manual entries show even when Dexcom is connected)
        let readingDescriptor = FetchDescriptor<GlucoseReading>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let readings = try? modelContext.fetch(readingDescriptor) {
            // If Dexcom is connected, only override if no Dexcom data yet
            if !dexcomConnected || currentReading == nil {
                currentReading = readings.first
            }
            recentReadings = Array(readings.prefix(12))
            timeInRange = InsulinCalculator.timeInRange(readings: readings)
            appLog("loadLocalData: \(readings.count) total readings, showing \(recentReadings.count) recent, latest=\(readings.first?.mgDL ?? 0) mg/dL", category: "DATA")
        } else {
            appLog("loadLocalData: no readings found", category: "DATA")
        }
    }
}
