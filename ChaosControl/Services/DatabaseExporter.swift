import Foundation

/// Writes human-readable Markdown/JSON files to Documents/Databases/
/// so the user can browse app data in the Apple Files app.
///
/// Structure mirrors ~/Chaos Control/Databases/Databases/:
///   Databases/
///     Dictionary.json
///     Food History Database.md
///     Insulin Corrections.md
///     Glucose Readings.md
///     Food/
///       {Category}/
///         {FoodName}.md       ← "Xg | serving | notes"
final class DatabaseExporter {
    static let shared = DatabaseExporter()

    private let baseDirectory: URL
    private let foodDirectory: URL
    private let shortDateFormatter: DateFormatter
    private let timestampFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.chaoscontrol.exporter", qos: .utility)

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDirectory = docs.appendingPathComponent("Databases", isDirectory: true)
        foodDirectory = baseDirectory.appendingPathComponent("Food", isDirectory: true)

        shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "M/d/yy"
        shortDateFormatter.locale = Locale(identifier: "en_US_POSIX")

        timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "M/d/yy h:mm a"
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Create base directory structure
        let defaultCategories = [
            "MEATS", "DRINKS", "DESSERTS", "FRUITS", "VEGETABLES",
            "GRAINS", "DAIRY", "SNACKS", "UNCATEGORIZED"
        ]
        for cat in defaultCategories {
            let dir = foodDirectory.appendingPathComponent(cat, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Food Export

    /// Write a single food item as a .md file under Food/{Category}/
    func exportFood(name: String, carbs: Double, serving: String, category: String, notes: String? = nil) {
        queue.async { [self] in
            let cat = category.isEmpty ? "UNCATEGORIZED" : category
            let dir = foodDirectory.appendingPathComponent(cat, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let safeName = name.replacingOccurrences(of: "/", with: "-")
            let fileURL = dir.appendingPathComponent("\(safeName).md")
            let servingText = serving.isEmpty ? "1x" : serving
            let content = "\(Int(carbs))g | \(servingText) | \(notes ?? name)\n"
            try? content.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Meal History

    /// Append a meal entry to Food History Database.md
    func exportMealToHistory(items: [(name: String, carbs: Double)], mealType: String, insulin: Double? = nil) {
        queue.async { [self] in
            let fileURL = baseDirectory.appendingPathComponent("Food History Database.md")
            ensureFileWithHeader(fileURL, header: "Date | Item | Carbs | Insulin | Type\n")

            let date = timestampFormatter.string(from: Date())
            let totalCarbs = items.reduce(0.0) { $0 + $1.carbs }
            let itemNames = items.map(\.name).joined(separator: ", ")
            let insulinStr = insulin.map { String(format: "%.1f", $0) } ?? "--"
            let entry = "\(date) | \(itemNames) | \(Int(totalCarbs))g | \(insulinStr) | \(mealType)\n"

            appendToFile(fileURL, content: entry)
        }
    }

    // MARK: - Insulin Doses

    /// Append a dose entry to Insulin Corrections.md
    func exportDose(glucose: Double, correction: Double, carbDose: Double, total: Double, iob: Double) {
        queue.async { [self] in
            let fileURL = baseDirectory.appendingPathComponent("Insulin Corrections.md")
            ensureFileWithHeader(fileURL, header: "Date | BG | Correction | Meal Dose | IOB | Total\n")

            let date = timestampFormatter.string(from: Date())
            let entry = "\(date) | \(Int(glucose)) | \(String(format: "%.1f", correction)) | \(String(format: "%.1f", carbDose)) | \(String(format: "%.1f", iob)) | \(String(format: "%.1f", total))\n"

            appendToFile(fileURL, content: entry)
        }
    }

    // MARK: - Glucose Readings

    /// Append a reading to Glucose Readings.md
    func exportReading(value: Double, trend: String, context: String?, source: String) {
        queue.async { [self] in
            let fileURL = baseDirectory.appendingPathComponent("Glucose Readings.md")
            ensureFileWithHeader(fileURL, header: "Date | Value | Trend | Context | Source\n")

            let date = timestampFormatter.string(from: Date())
            let ctx = context ?? "--"
            let entry = "\(date) | \(Int(value)) mg/dL | \(trend) | \(ctx) | \(source)\n"

            appendToFile(fileURL, content: entry)
        }
    }

    // MARK: - Settings

    /// Write current settings to Dictionary.json
    func exportSettings(icr: Double, isf: Double, target: Double, actionDuration: Double, lowThreshold: Double, highThreshold: Double) {
        queue.async { [self] in
            let fileURL = baseDirectory.appendingPathComponent("Dictionary.json")
            let dict: [String: Any] = [
                "insulin_to_carb_ratio": icr,
                "insulin_sensitivity_factor": isf,
                "target_glucose": target,
                "insulin_action_duration_hours": actionDuration,
                "low_threshold": lowThreshold,
                "high_threshold": highThreshold,
                "updated": ISO8601DateFormatter().string(from: Date())
            ]
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    // MARK: - Private Helpers

    private func ensureFileWithHeader(_ url: URL, header: String) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? header.data(using: .utf8)?.write(to: url, options: .atomic)
        }
    }

    private func appendToFile(_ url: URL, content: String) {
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                if let data = content.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? content.data(using: .utf8)?.write(to: url, options: .atomic)
        }
    }
}
