import Foundation

// MARK: - Dexcom Share API Service
// Native Swift implementation of the Dexcom Share API (equivalent to pydexcom)

enum DexcomRegion: String, CaseIterable {
    case us = "us"
    case ous = "ous"
    case jp = "jp"

    var baseURL: String {
        switch self {
        case .us: return "https://share2.dexcom.com/ShareWebServices/Services/"
        case .ous: return "https://shareous1.dexcom.com/ShareWebServices/Services/"
        case .jp: return "https://share.dexcom.jp/ShareWebServices/Services/"
        }
    }

    var applicationId: String {
        switch self {
        case .us, .ous: return "d89443d2-327c-4a6f-89e5-496bbb0317db"
        case .jp: return "d8665ade-9673-4e27-9ff6-92db4ce13d13"
        }
    }
}

enum DexcomError: Error, LocalizedError {
    case invalidCredentials
    case sessionExpired
    case maxAttemptsExceeded
    case invalidResponse
    case networkError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid Dexcom credentials"
        case .sessionExpired: return "Dexcom session expired"
        case .maxAttemptsExceeded: return "Too many login attempts. Try again later."
        case .invalidResponse: return "Invalid response from Dexcom"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .noData: return "No glucose data available"
        }
    }
}

// MARK: - Dexcom API Response Types

struct DexcomGlucoseResponse: Decodable {
    let WT: String
    let ST: String
    let DT: String
    let Value: Int
    let Trend: String
}

actor DexcomShareService {
    private let region: DexcomRegion
    private let session = URLSession.shared
    private var accountId: String?
    private var sessionId: String?

    private let defaultUUID = "00000000-0000-0000-0000-000000000000"

    init(region: DexcomRegion = .us) {
        self.region = region
    }

    // MARK: - Public API

    /// Authenticate with username and password, establishing a session
    func authenticate(username: String, password: String) async throws {
        // Step 1: Get account ID from username
        accountId = try await getAccountId(username: username, password: password)

        // Step 2: Get session ID from account ID
        guard let accountId else { throw DexcomError.invalidCredentials }
        sessionId = try await getSessionId(accountId: accountId, password: password)
    }

    /// Authenticate with account ID directly
    func authenticate(accountId: String, password: String) async throws {
        self.accountId = accountId
        sessionId = try await getSessionId(accountId: accountId, password: password)
    }

    /// Get glucose readings from the last N minutes (max 1440 = 24 hours)
    func getGlucoseReadings(minutes: Int = 1440, maxCount: Int = 288) async throws -> [GlucoseReading] {
        guard let sessionId, sessionId != defaultUUID else {
            throw DexcomError.sessionExpired
        }

        let clampedMinutes = max(1, min(1440, minutes))
        let clampedCount = max(1, min(288, maxCount))

        do {
            return try await fetchGlucoseReadings(sessionId: sessionId, minutes: clampedMinutes, maxCount: clampedCount)
        } catch DexcomError.sessionExpired {
            // Re-authenticate and retry once
            guard let accountId else { throw DexcomError.sessionExpired }
            let password = try KeychainService.getPassword()
            self.sessionId = try await getSessionId(accountId: accountId, password: password)
            guard let newSessionId = self.sessionId else { throw DexcomError.sessionExpired }
            return try await fetchGlucoseReadings(sessionId: newSessionId, minutes: clampedMinutes, maxCount: clampedCount)
        }
    }

    /// Get the latest glucose reading (last 24 hours)
    func getLatestReading() async throws -> GlucoseReading? {
        let readings = try await getGlucoseReadings(minutes: 1440, maxCount: 1)
        return readings.first
    }

    /// Get the current glucose reading (last 10 minutes)
    func getCurrentReading() async throws -> GlucoseReading? {
        let readings = try await getGlucoseReadings(minutes: 10, maxCount: 1)
        return readings.first
    }

    var isAuthenticated: Bool {
        sessionId != nil && sessionId != defaultUUID
    }

    func clearSession() {
        sessionId = nil
        accountId = nil
    }

    // MARK: - Private API Calls

    private func getAccountId(username: String, password: String) async throws -> String {
        let url = URL(string: "\(region.baseURL)General/AuthenticatePublisherAccount")!
        let body: [String: String] = [
            "accountName": username,
            "password": password,
            "applicationId": region.applicationId
        ]

        let result: String = try await postJSON(url: url, body: body)
        let cleaned = result.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        guard cleaned != defaultUUID else {
            throw DexcomError.invalidCredentials
        }

        return cleaned
    }

    private func getSessionId(accountId: String, password: String) async throws -> String {
        let url = URL(string: "\(region.baseURL)General/LoginPublisherAccountById")!
        let body: [String: String] = [
            "accountId": accountId,
            "password": password,
            "applicationId": region.applicationId
        ]

        let result: String = try await postJSON(url: url, body: body)
        let cleaned = result.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        guard cleaned != defaultUUID else {
            throw DexcomError.invalidCredentials
        }

        return cleaned
    }

    private func fetchGlucoseReadings(sessionId: String, minutes: Int, maxCount: Int) async throws -> [GlucoseReading] {
        var components = URLComponents(string: "\(region.baseURL)Publisher/ReadPublisherLatestGlucoseValues")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "minutes", value: String(minutes)),
            URLQueryItem(name: "maxCount", value: String(maxCount))
        ]

        guard let url = components.url else {
            throw DexcomError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DexcomError.invalidResponse
        }

        // Check for session errors in response
        if httpResponse.statusCode == 500 {
            if let errorBody = String(data: data, encoding: .utf8),
               errorBody.contains("SessionIdNotFound") || errorBody.contains("SessionNotValid") {
                throw DexcomError.sessionExpired
            }
        }

        guard httpResponse.statusCode == 200 else {
            throw DexcomError.invalidResponse
        }

        let decoder = JSONDecoder()
        let dexcomReadings = try decoder.decode([DexcomGlucoseResponse].self, from: data)

        return dexcomReadings.map { response in
            let timestamp = parseDexcomDate(response.DT) ?? Date()
            let trend = TrendDirection(dexcomString: response.Trend)

            return GlucoseReading(
                value: Double(response.Value),
                trend: trend,
                timestamp: timestamp,
                source: .dexcom
            )
        }
    }

    // MARK: - Helpers

    private func postJSON<T: Decodable>(url: URL, body: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DexcomError.invalidResponse
            }

            // Check for error responses
            if httpResponse.statusCode != 200 {
                if let errorBody = String(data: data, encoding: .utf8) {
                    if errorBody.contains("AccountPasswordInvalid") {
                        throw DexcomError.invalidCredentials
                    }
                    if errorBody.contains("SSO_AuthenticateMaxAttemptsExceeded") {
                        throw DexcomError.maxAttemptsExceeded
                    }
                    if errorBody.contains("SessionIdNotFound") || errorBody.contains("SessionNotValid") {
                        throw DexcomError.sessionExpired
                    }
                }
                throw DexcomError.invalidResponse
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DexcomError {
            throw error
        } catch let error as DecodingError {
            throw DexcomError.invalidResponse
        } catch {
            throw DexcomError.networkError(error)
        }
    }

    /// Parse Dexcom date format: "Date(1691455258000-0400)"
    private func parseDexcomDate(_ dateString: String) -> Date? {
        // Extract timestamp from "Date(XXXXX...)" or "Date(XXXXX-0400)"
        let pattern = #"Date\((\d+)([+-]\d{4})?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
              let timestampRange = Range(match.range(at: 1), in: dateString) else {
            return nil
        }

        let timestampMs = Double(dateString[timestampRange]) ?? 0
        var date = Date(timeIntervalSince1970: timestampMs / 1000)

        // Apply timezone offset if present
        if match.numberOfRanges > 2,
           let offsetRange = Range(match.range(at: 2), in: dateString) {
            let offsetStr = String(dateString[offsetRange])
            let sign = offsetStr.hasPrefix("-") ? -1 : 1
            let digits = offsetStr.dropFirst()
            if let hours = Int(digits.prefix(2)),
               let minutes = Int(digits.suffix(2)) {
                let offsetSeconds = sign * (hours * 3600 + minutes * 60)
                date = date.addingTimeInterval(TimeInterval(offsetSeconds))
            }
        }

        return date
    }
}
