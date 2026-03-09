import Foundation
import RipoDomain

public struct ContextSuggestion: Sendable, Equatable {
    public var title: String
    public var body: String
    public var templateHints: [String]

    public init(title: String, body: String, templateHints: [String]) {
        self.title = title
        self.body = body
        self.templateHints = templateHints
    }
}

public struct ContextSuggestionService: Sendable {
    private let weatherProvider: WeatherProvider
    private let placeProvider: PlaceContextProvider

    public init(weatherProvider: WeatherProvider, placeProvider: PlaceContextProvider) {
        self.weatherProvider = weatherProvider
        self.placeProvider = placeProvider
    }

    public func suggest() async throws -> ContextSuggestion {
        let place = try await placeProvider.currentPlaceContext()
        let weather = try await weatherProvider.currentWeather(latitude: place.latitude, longitude: place.longitude)

        if weather.condition == .sunny,
           let distance = place.distanceToBeachMeters,
           distance <= 1_500
        {
            return ContextSuggestion(
                title: "Sahil Molası",
                body: "Hava güneşli. \(place.label) yakınında kısa bir sahil yürüyüşü için 5 dakika ayır.",
                templateHints: ["idea", "daily", "journal_walk"]
            )
        }

        switch weather.condition {
        case .rainy:
            return ContextSuggestion(
                title: "Yağmurlu Gün Notu",
                body: "Yağmurlu hava için iç mekanda kısa plan notu çıkar.",
                templateHints: ["daily", "project", "journal"]
            )
        case .sunny:
            return ContextSuggestion(
                title: "Açık Hava Fikri",
                body: "Hava açık. Kısa bir açık hava aktivitesi ve gün notu planla.",
                templateHints: ["idea", "daily", "journal"]
            )
        case .cloudy, .windy:
            return ContextSuggestion(
                title: "Odak Seansı",
                body: "Bugün için 25 dakikalık odaklı çalışma notu oluştur.",
                templateHints: ["project", "meeting", "daily"]
            )
        case .snowy:
            return ContextSuggestion(
                title: "Kış Günü Günlüğü",
                body: "Sıcak bir içecek eşliğinde kısa bir günlük girişi yap.",
                templateHints: ["journal", "daily"]
            )
        case .unknown:
            return ContextSuggestion(
                title: "Hızlı Brain Dump",
                body: "3 dakikalık hızlı not boşaltma yap.",
                templateHints: ["idea", "daily"]
            )
        }
    }
}
