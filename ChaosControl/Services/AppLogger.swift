import Foundation

/// File-based logger that writes to Documents/Logs/ (visible in Apple Files app).
final class AppLogger {
    static let shared = AppLogger()

    private let logDirectory: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.chaoscontrol.logger", qos: .utility)

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logDirectory = docs.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Write a boot marker
        log("===== App launched =====", category: "SYSTEM")
    }

    /// Current log file path (one file per day).
    private var currentLogFile: URL {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        let filename = "chaos-\(dayFormatter.string(from: Date())).log"
        return logDirectory.appendingPathComponent(filename)
    }

    /// Write a log entry.
    func log(_ message: String, category: String = "APP", file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let source = (file as NSString).lastPathComponent
        let entry = "[\(timestamp)] [\(category)] [\(source):\(line)] \(message)\n"

        queue.async { [weak self] in
            guard let self else { return }
            let fileURL = self.currentLogFile
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    if let data = entry.data(using: .utf8) {
                        handle.write(data)
                    }
                    handle.closeFile()
                }
            } else {
                try? entry.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            }
        }

        #if DEBUG
        print(entry, terminator: "")
        #endif
    }

    /// Convenience methods for severity levels.
    func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, category: "INFO", file: file, line: line)
    }

    func warn(_ message: String, file: String = #file, line: Int = #line) {
        log(message, category: "WARN", file: file, line: line)
    }

    func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, category: "ERROR", file: file, line: line)
    }

    func data(_ message: String, file: String = #file, line: Int = #line) {
        log(message, category: "DATA", file: file, line: line)
    }

    /// Prune log files older than 7 days.
    func pruneOldLogs(daysToKeep: Int = 7) {
        queue.async { [weak self] in
            guard let self else { return }
            let cutoff = Calendar.current.date(byAdding: .day, value: -daysToKeep, to: Date())!
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: self.logDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            ) else { return }

            for file in files {
                guard let attrs = try? file.resourceValues(forKeys: [.creationDateKey]),
                      let created = attrs.creationDate,
                      created < cutoff else { continue }
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

/// Shorthand global accessor.
func appLog(_ message: String, category: String = "APP", file: String = #file, line: Int = #line) {
    AppLogger.shared.log(message, category: category, file: file, line: line)
}
