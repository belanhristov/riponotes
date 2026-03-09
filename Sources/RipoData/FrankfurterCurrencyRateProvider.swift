import Foundation
import RipoDomain

public enum FrankfurterRateError: Error {
    case invalidURL
    case invalidResponse
    case missingRate
}

public final class FrankfurterCurrencyRateProvider: CurrencyRateProvider, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://api.frankfurter.app")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func rate(from baseCurrency: String, to targetCurrency: String) async throws -> Double {
        if baseCurrency.uppercased() == targetCurrency.uppercased() {
            return 1
        }

        guard var components = URLComponents(url: baseURL.appendingPathComponent("latest"), resolvingAgainstBaseURL: false) else {
            throw FrankfurterRateError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "from", value: baseCurrency.uppercased()),
            URLQueryItem(name: "to", value: targetCurrency.uppercased()),
        ]

        guard let url = components.url else { throw FrankfurterRateError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw FrankfurterRateError.invalidResponse
        }

        return try Self.parseRate(data: data, targetCurrency: targetCurrency)
    }

    static func parseRate(data: Data, targetCurrency: String) throws -> Double {
        let decoded = try JSONDecoder().decode(FrankfurterLatestResponse.self, from: data)
        guard let rate = decoded.rates[targetCurrency.uppercased()] else {
            throw FrankfurterRateError.missingRate
        }
        return rate
    }
}

private struct FrankfurterLatestResponse: Decodable {
    let rates: [String: Double]
}
