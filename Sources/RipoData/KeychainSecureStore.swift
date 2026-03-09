import Foundation
import RipoDomain

#if canImport(Security)
import Security

public enum KeychainSecureStoreError: Error {
    case unexpectedStatus(OSStatus)
    case decodeError
}

public actor KeychainSecureStore: SecureStore {
    private let service: String

    public init(service: String = "com.ripo.notes.secure") {
        self.service = service
    }

    public func setString(_ value: String, for key: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainSecureStoreError.decodeError
        }
        try await setData(data, for: key)
    }

    public func string(for key: String) async throws -> String? {
        guard let data = try await self.data(for: key) else { return nil }
        guard let value = String(data: data, encoding: .utf8) else {
            throw KeychainSecureStoreError.decodeError
        }
        return value
    }

    public func setData(_ value: Data, for key: String) async throws {
        let query = baseQuery(for: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            let attrs: [String: Any] = [kSecValueData as String: value]
            let update = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
            guard update == errSecSuccess else {
                throw KeychainSecureStoreError.unexpectedStatus(update)
            }
            return
        }

        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = value
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainSecureStoreError.unexpectedStatus(addStatus)
            }
            return
        }

        throw KeychainSecureStoreError.unexpectedStatus(status)
    }

    public func data(for key: String) async throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainSecureStoreError.unexpectedStatus(status)
        }

        return item as? Data
    }

    public func removeValue(for key: String) async throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainSecureStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}

#endif
