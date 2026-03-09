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

    public static func makeCurrencyRateProvider(useProductionAdapters: Bool) -> CurrencyRateProvider {
        if useProductionAdapters {
            return FrankfurterCurrencyRateProvider()
        }
        return InMemoryCurrencyRateProvider(rates: ["USD_EUR": 0.9, "USD_TRY": 36.0, "EUR_TRY": 40.0])
    }

    public static func makeFxQuoteCache(useProductionAdapters: Bool) -> FxQuoteCache {
        if useProductionAdapters {
            return UserDefaultsFxQuoteCache()
        }
        return InMemoryFxQuoteCache()
    }
}
