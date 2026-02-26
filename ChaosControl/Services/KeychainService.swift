import Foundation
import Security

// MARK: - Keychain Service
// Secure local storage for Dexcom credentials

enum KeychainService {
    private static let service = "com.chaoscontrol.dexcom"
    private static let usernameKey = "dexcom_username"
    private static let passwordKey = "dexcom_password"
    private static let accountIdKey = "dexcom_account_id"

    // MARK: - Username

    static func saveUsername(_ username: String) throws {
        try save(key: usernameKey, value: username)
    }

    static func getUsername() throws -> String {
        try load(key: usernameKey)
    }

    static func deleteUsername() {
        delete(key: usernameKey)
    }

    // MARK: - Password

    static func savePassword(_ password: String) throws {
        try save(key: passwordKey, value: password)
    }

    static func getPassword() throws -> String {
        try load(key: passwordKey)
    }

    static func deletePassword() {
        delete(key: passwordKey)
    }

    // MARK: - Account ID

    static func saveAccountId(_ accountId: String) throws {
        try save(key: accountIdKey, value: accountId)
    }

    static func getAccountId() throws -> String {
        try load(key: accountIdKey)
    }

    static func deleteAccountId() {
        delete(key: accountIdKey)
    }

    // MARK: - Bulk Operations

    static func clearAll() {
        deleteUsername()
        deletePassword()
        deleteAccountId()
    }

    static var hasCredentials: Bool {
        (try? getUsername()) != nil && (try? getPassword()) != nil
    }

    // MARK: - Private Helpers

    private static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private static func load(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }

        return string
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode value"
        case .saveFailed(let status): return "Keychain save failed: \(status)"
        case .itemNotFound: return "Credentials not found"
        }
    }
}
