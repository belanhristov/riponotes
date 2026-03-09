import Foundation
import RipoDomain

#if canImport(LocalAuthentication)
import LocalAuthentication

public enum LocalAuthenticationError: Error {
    case notAvailable
}

public actor LocalAuthenticationAuthenticator: AppAuthenticator {
    public init() {}

    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error {
                throw error
            }
            throw LocalAuthenticationError.notAvailable
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                if let evalError {
                    continuation.resume(throwing: evalError)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}

#endif
