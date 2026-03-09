import Foundation
import RipoDomain

public enum TravelPlannerError: Error {
    case invalidDateRange
    case tripNotFound
    case invalidDuration
    case invalidDailyEstimate
}

public struct TravelPlannerService: Sendable {
    private let tripRepository: TripRepository
    private let currencyRateProvider: CurrencyRateProvider
    private let weatherProvider: WeatherProvider

    public init(tripRepository: TripRepository, currencyRateProvider: CurrencyRateProvider, weatherProvider: WeatherProvider) {
        self.tripRepository = tripRepository
        self.currencyRateProvider = currencyRateProvider
        self.weatherProvider = weatherProvider
    }

    @discardableResult
    public func createTrip(
        ownerUserId: UUID,
        title: String,
        origin: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        baseCurrency: String,
        targetCurrency: String,
        now: Date = .now
    ) async throws -> Trip {
        guard endDate >= startDate else { throw TravelPlannerError.invalidDateRange }

        let trip = Trip(
            ownerUserId: ownerUserId,
            title: title,
            origin: origin,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            baseCurrency: baseCurrency.uppercased(),
            targetCurrency: targetCurrency.uppercased(),
            createdAt: now,
            updatedAt: now
        )
        try await tripRepository.upsertTrip(trip)
        return trip
    }

    @discardableResult
    public func addFlightSegment(
        tripId: UUID,
        providerName: String,
        confirmationCode: String,
        departureAt: Date,
        arrivalAt: Date,
        notes: String = ""
    ) async throws -> TripSegment {
        let segment = TripSegment(
            tripId: tripId,
            type: .flight,
            startAt: departureAt,
            endAt: arrivalAt,
            providerName: providerName,
            confirmationCode: confirmationCode,
            notes: notes
        )
        try await tripRepository.upsertSegment(segment)
        return segment
    }

    @discardableResult
    public func addHotelSegment(
        tripId: UUID,
        hotelName: String,
        confirmationCode: String,
        checkIn: Date,
        checkOut: Date,
        notes: String = ""
    ) async throws -> TripSegment {
        let segment = TripSegment(
            tripId: tripId,
            type: .hotel,
            startAt: checkIn,
            endAt: checkOut,
            providerName: hotelName,
            confirmationCode: confirmationCode,
            notes: notes
        )
        try await tripRepository.upsertSegment(segment)
        return segment
    }

    @discardableResult
    public func addChecklistItem(
        tripId: UUID,
        category: TripChecklistCategory,
        text: String,
        isCritical: Bool = false,
        dueAt: Date? = nil
    ) async throws -> TripChecklistItem {
        let item = TripChecklistItem(
            tripId: tripId,
            category: category,
            text: text,
            isDone: false,
            isCritical: isCritical,
            dueAt: dueAt
        )
        try await tripRepository.upsertChecklistItem(item)
        return item
    }

    @discardableResult
    public func toggleChecklistItem(_ item: TripChecklistItem) async throws -> TripChecklistItem {
        var next = item
        next.isDone.toggle()
        try await tripRepository.upsertChecklistItem(next)
        return next
    }

    @discardableResult
    public func addPackingItem(
        tripId: UUID,
        category: PackingCategory,
        text: String,
        quantity: Int,
        isCritical: Bool = false
    ) async throws -> PackingItem {
        let item = PackingItem(
            tripId: tripId,
            category: category,
            text: text,
            quantity: max(1, quantity),
            isDone: false,
            isCritical: isCritical
        )
        try await tripRepository.upsertPackingItem(item)
        return item
    }

    @discardableResult
    public func togglePackingItem(_ item: PackingItem) async throws -> PackingItem {
        var next = item
        next.isDone.toggle()
        try await tripRepository.upsertPackingItem(next)
        return next
    }

    @discardableResult
    public func estimateBudget(
        tripId: UUID,
        dailySpendInBaseCurrency: Double,
        confidence: Double = 0.75,
        now: Date = .now
    ) async throws -> TripBudgetEstimate {
        guard dailySpendInBaseCurrency > 0 else { throw TravelPlannerError.invalidDailyEstimate }
        guard let trip = try await tripRepository.trip(by: tripId) else { throw TravelPlannerError.tripNotFound }

        let days = max(1, Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0)
        let fx = try await currencyRateProvider.rate(from: trip.baseCurrency, to: trip.targetCurrency)
        let total = Double(days) * dailySpendInBaseCurrency * fx

        let estimate = TripBudgetEstimate(
            tripId: tripId,
            estimatedTotal: total,
            currency: trip.targetCurrency,
            dailyEstimate: dailySpendInBaseCurrency * fx,
            fxRateUsed: fx,
            confidence: min(max(confidence, 0), 1),
            generatedAt: now
        )
        try await tripRepository.upsertBudgetEstimate(estimate)
        return estimate
    }

    public func weatherSummaryForTripDestination(tripId: UUID, latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        guard try await tripRepository.trip(by: tripId) != nil else { throw TravelPlannerError.tripNotFound }
        return try await weatherProvider.currentWeather(latitude: latitude, longitude: longitude)
    }
}
