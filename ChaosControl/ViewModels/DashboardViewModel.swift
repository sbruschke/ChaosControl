import Foundation
import SwiftData
import Combine

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

    func refreshDexcomData() async {
        guard await dexcomService.isAuthenticated else { return }
        isLoading = true
        do {
            let readings = try await dexcomService.getGlucoseReadings(minutes: 1440, maxCount: 288)
            if let latest = readings.first {
                currentReading = latest
            }
            recentReadings = Array(readings.prefix(12))

            let last24h = readings
            timeInRange = InsulinCalculator.timeInRange(readings: last24h)
            dexcomConnected = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func startAutoRefresh(modelContext: ModelContext) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { break }
                await self?.refreshDexcomData()
                self?.loadLocalData(modelContext: modelContext)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func tryAutoConnect() async {
        guard KeychainService.hasCredentials else { return }
        do {
            let username = try KeychainService.getUsername()
            let password = try KeychainService.getPassword()
            try await dexcomService.authenticate(username: username, password: password)
            dexcomConnected = true
            await refreshDexcomData()
        } catch {
            // Silently fail - user can reconnect manually
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

        // Load manual readings if no Dexcom data
        if currentReading == nil {
            let readingDescriptor = FetchDescriptor<GlucoseReading>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let readings = try? modelContext.fetch(readingDescriptor) {
                currentReading = readings.first
                recentReadings = Array(readings.prefix(12))
                timeInRange = InsulinCalculator.timeInRange(readings: readings)
            }
        }
    }
}
