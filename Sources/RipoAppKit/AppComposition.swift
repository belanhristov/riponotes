import Foundation
import RipoData
import RipoDomain
import RipoUseCases

public enum AppComposition {
    public static func makeJournalSecurityService(useProductionAdapters: Bool) -> JournalSecurityService {
        if useProductionAdapters {
            #if canImport(Security) && canImport(LocalAuthentication)
            return JournalSecurityService(
                secureStore: KeychainSecureStore(),
                authenticator: LocalAuthenticationAuthenticator()
            )
            #else
            return JournalSecurityService(
                secureStore: InMemorySecureStore(),
                authenticator: InMemoryAppAuthenticator(nextResult: true)
            )
            #endif
        }

        return JournalSecurityService(
            secureStore: InMemorySecureStore(),
            authenticator: InMemoryAppAuthenticator(nextResult: true)
        )
    }
}
