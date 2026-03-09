import Foundation
import RipoDomain

public final class UserDefaultsFxQuoteCache: FxQuoteCache, @unchecked Sendable {
    private struct StoredQuote: Codable {
        var rate: Double
        var quotedAt: Date
    }

    private let defaults: UserDefaults
    private let namespace: String

    public init(defaults: UserDefaults = .standard, namespace: String = "com.ripo.fx") {
        self.defaults = defaults
        self.namespace = namespace
    }

    public func save(rate: Double, from baseCurrency: String, to targetCurrency: String, quotedAt: Date) async throws {
        let key = namespacedKey(from: baseCurrency, to: targetCurrency)
        let payload = StoredQuote(rate: rate, quotedAt: quotedAt)
        let data = try JSONEncoder().encode(payload)
        defaults.set(data, forKey: key)
    }

    public func load(from baseCurrency: String, to targetCurrency: String) async throws -> (rate: Double, quotedAt: Date)? {
        let key = namespacedKey(from: baseCurrency, to: targetCurrency)
        guard let data = defaults.data(forKey: key) else { return nil }
        let payload = try JSONDecoder().decode(StoredQuote.self, from: data)
        return (rate: payload.rate, quotedAt: payload.quotedAt)
    }

    private func namespacedKey(from baseCurrency: String, to targetCurrency: String) -> String {
        "\(namespace).\(baseCurrency.uppercased())_\(targetCurrency.uppercased())"
    }
}
