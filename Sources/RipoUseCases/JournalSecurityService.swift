import Foundation
import RipoDomain

#if canImport(CryptoKit)
import CryptoKit
#endif

public enum JournalSecurityError: Error {
    case invalidPasscode
    case lockNotEnabled
    case locked
    case keyUnavailable
    case biometricFailed
    case cryptoUnavailable
    case decryptionFailed
}

public struct JournalSecurityStatus: Sendable, Equatable {
    public var isLockEnabled: Bool
    public var isUnlocked: Bool

    public init(isLockEnabled: Bool, isUnlocked: Bool) {
        self.isLockEnabled = isLockEnabled
        self.isUnlocked = isUnlocked
    }
}

public actor JournalSecurityService {
    private enum Keys {
        static let passcodeHash = "journal.passcode.hash"
        static let encryptionKey = "journal.encryption.key"
    }

    private let secureStore: SecureStore
    private let authenticator: AppAuthenticator
    private var isUnlocked = false

    public init(secureStore: SecureStore, authenticator: AppAuthenticator) {
        self.secureStore = secureStore
        self.authenticator = authenticator
    }

    public func status() async throws -> JournalSecurityStatus {
        let enabled = try await secureStore.string(for: Keys.passcodeHash) != nil
        return JournalSecurityStatus(isLockEnabled: enabled, isUnlocked: enabled ? isUnlocked : true)
    }

    public func enableLock(passcode: String) async throws {
        let normalized = passcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 4 else {
            throw JournalSecurityError.invalidPasscode
        }

        try await secureStore.setString(sha256(normalized), for: Keys.passcodeHash)
        if try await secureStore.data(for: Keys.encryptionKey) == nil {
            let key = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            try await secureStore.setData(key, for: Keys.encryptionKey)
        }
        isUnlocked = true
    }

    public func disableLock() async throws {
        try await secureStore.removeValue(for: Keys.passcodeHash)
        isUnlocked = false
    }

    public func lock() async throws {
        guard try await secureStore.string(for: Keys.passcodeHash) != nil else {
            throw JournalSecurityError.lockNotEnabled
        }
        isUnlocked = false
    }

    public func unlockWithPasscode(_ passcode: String) async throws {
        guard let hash = try await secureStore.string(for: Keys.passcodeHash) else {
            throw JournalSecurityError.lockNotEnabled
        }
        guard sha256(passcode) == hash else {
            throw JournalSecurityError.invalidPasscode
        }
        isUnlocked = true
    }

    public func unlockWithBiometrics(reason: String = "Unlock Journal") async throws {
        guard try await secureStore.string(for: Keys.passcodeHash) != nil else {
            throw JournalSecurityError.lockNotEnabled
        }
        let ok = try await authenticator.authenticate(reason: reason)
        guard ok else { throw JournalSecurityError.biometricFailed }
        isUnlocked = true
    }

    public func encrypt(_ plaintext: String) async throws -> String {
        guard try await secureStore.string(for: Keys.passcodeHash) != nil else {
            return plaintext
        }
        guard isUnlocked else { throw JournalSecurityError.locked }
        guard let key = try await secureStore.data(for: Keys.encryptionKey) else {
            throw JournalSecurityError.keyUnavailable
        }

        #if canImport(CryptoKit)
        let symmetricKey = SymmetricKey(data: key)
        let sealed = try AES.GCM.seal(Data(plaintext.utf8), using: symmetricKey)
        guard let combined = sealed.combined else { throw JournalSecurityError.decryptionFailed }
        return combined.base64EncodedString()
        #else
        throw JournalSecurityError.cryptoUnavailable
        #endif
    }

    public func decrypt(_ ciphertext: String) async throws -> String {
        guard try await secureStore.string(for: Keys.passcodeHash) != nil else {
            return ciphertext
        }
        guard isUnlocked else { throw JournalSecurityError.locked }
        guard let key = try await secureStore.data(for: Keys.encryptionKey) else {
            throw JournalSecurityError.keyUnavailable
        }
        guard let raw = Data(base64Encoded: ciphertext) else {
            throw JournalSecurityError.decryptionFailed
        }

        #if canImport(CryptoKit)
        let symmetricKey = SymmetricKey(data: key)
        let box = try AES.GCM.SealedBox(combined: raw)
        let data = try AES.GCM.open(box, using: symmetricKey)
        guard let text = String(data: data, encoding: .utf8) else {
            throw JournalSecurityError.decryptionFailed
        }
        return text
        #else
        throw JournalSecurityError.cryptoUnavailable
        #endif
    }

    private func sha256(_ input: String) -> String {
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        return input
        #endif
    }
}
