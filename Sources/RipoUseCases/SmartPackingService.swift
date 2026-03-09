import Foundation
import RipoDomain

public enum SmartPackingError: Error {
    case tripNotFound
}

public struct SmartPackingConfig: Sendable {
    public var weather: WeatherCondition
    public var activities: [TravelActivity]
    public var travelers: Int
    public var laundryAccess: Bool

    public init(
        weather: WeatherCondition,
        activities: [TravelActivity],
        travelers: Int = 1,
        laundryAccess: Bool = false
    ) {
        self.weather = weather
        self.activities = activities
        self.travelers = max(1, travelers)
        self.laundryAccess = laundryAccess
    }
}

public struct SmartPackingService: Sendable {
    private let tripRepository: TripRepository

    public init(tripRepository: TripRepository) {
        self.tripRepository = tripRepository
    }

    public func generateAndSave(tripId: UUID, config: SmartPackingConfig) async throws -> [PackingItem] {
        guard let trip = try await tripRepository.trip(by: tripId) else {
            throw SmartPackingError.tripNotFound
        }

        let days = max(1, Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0)
        let recommended = recommendations(days: days, config: config)

        var saved: [PackingItem] = []
        for rec in recommended {
            let item = PackingItem(
                tripId: tripId,
                category: rec.category,
                text: rec.text,
                quantity: rec.quantity,
                isDone: false,
                isCritical: rec.isCritical
            )
            try await tripRepository.upsertPackingItem(item)
            saved.append(item)
        }
        return saved
    }

    private func recommendations(days: Int, config: SmartPackingConfig) -> [(category: PackingCategory, text: String, quantity: Int, isCritical: Bool)] {
        let repeatFactor = config.laundryAccess ? min(4, days) : min(days + 1, 12)
        var list: [(PackingCategory, String, Int, Bool)] = [
            (.documents, "Passport", config.travelers, true),
            (.tech, "Phone Charger", config.travelers, true),
            (.clothes, "T-Shirts", repeatFactor * config.travelers, false),
            (.clothes, "Underwear", repeatFactor * config.travelers, false),
            (.clothes, "Socks", repeatFactor * config.travelers, false),
        ]

        switch config.weather {
        case .sunny:
            list.append((.clothes, "Hat", config.travelers, false))
            list.append((.custom, "Sunscreen", config.travelers, false))
            list.append((.custom, "Sunglasses", config.travelers, false))
        case .rainy:
            list.append((.clothes, "Rain Jacket", config.travelers, false))
            list.append((.custom, "Umbrella", config.travelers, false))
        case .snowy:
            list.append((.clothes, "Winter Coat", config.travelers, true))
            list.append((.clothes, "Thermal Layers", repeatFactor * config.travelers, false))
        case .windy:
            list.append((.clothes, "Windbreaker", config.travelers, false))
        case .cloudy, .unknown:
            break
        }

        for activity in config.activities {
            switch activity {
            case .beach:
                list.append((.clothes, "Swimsuit", config.travelers, false))
                list.append((.custom, "Beach Towel", config.travelers, false))
            case .business:
                list.append((.clothes, "Formal Shirt", repeatFactor * config.travelers, false))
                list.append((.tech, "Laptop + Charger", config.travelers, true))
            case .cityWalk:
                list.append((.clothes, "Comfortable Shoes", config.travelers, false))
            case .hiking:
                list.append((.clothes, "Hiking Shoes", config.travelers, true))
                list.append((.custom, "Water Bottle", config.travelers, false))
            case .nightlife:
                list.append((.clothes, "Evening Outfit", config.travelers, false))
            case .winterSports:
                list.append((.clothes, "Gloves", config.travelers, true))
                list.append((.clothes, "Beanie", config.travelers, false))
            }
        }

        return list
    }
}
