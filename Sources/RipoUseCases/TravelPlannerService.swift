import Foundation
import RipoDomain

public enum TravelPlannerError: Error {
    case invalidDateRange
    case tripNotFound
    case invalidDuration
    case invalidDailyEstimate
}

public struct TripFxQuote: Sendable, Equatable {
    public var baseCurrency: String
    public var targetCurrency: String
    public var rate: Double
    public var quotedAt: Date
    public var source: FxQuoteSource

    public init(baseCurrency: String, targetCurrency: String, rate: Double, quotedAt: Date, source: FxQuoteSource) {
        self.baseCurrency = baseCurrency
        self.targetCurrency = targetCurrency
        self.rate = rate
        self.quotedAt = quotedAt
        self.source = source
    }
}

public struct TravelPlannerService: Sendable {
    private let tripRepository: TripRepository
    private let currencyRateProvider: CurrencyRateProvider
    private let weatherProvider: WeatherProvider
    private let fxQuoteCache: FxQuoteCache?

    public init(
        tripRepository: TripRepository,
        currencyRateProvider: CurrencyRateProvider,
        weatherProvider: WeatherProvider,
        fxQuoteCache: FxQuoteCache? = nil
    ) {
        self.tripRepository = tripRepository
        self.currencyRateProvider = currencyRateProvider
        self.weatherProvider = weatherProvider
        self.fxQuoteCache = fxQuoteCache
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

    @discardableResult
    public func estimateBudgetFromExpenseProfile(
        tripId: UUID,
        profile: TripExpenseProfile,
        confidence: Double = 0.8,
        now: Date = .now
    ) async throws -> TripBudgetEstimate {
        guard profile.dailyTotal > 0 else { throw TravelPlannerError.invalidDailyEstimate }
        return try await estimateBudget(
            tripId: tripId,
            dailySpendInBaseCurrency: profile.dailyTotal,
            confidence: confidence,
            now: now
        )
    }

    public func weatherSummaryForTripDestination(tripId: UUID, latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        guard try await tripRepository.trip(by: tripId) != nil else { throw TravelPlannerError.tripNotFound }
        return try await weatherProvider.currentWeather(latitude: latitude, longitude: longitude)
    }

    public func currentFxQuote(tripId: UUID, now: Date = .now) async throws -> TripFxQuote {
        guard let trip = try await tripRepository.trip(by: tripId) else { throw TravelPlannerError.tripNotFound }
        do {
            let rate = try await currencyRateProvider.rate(from: trip.baseCurrency, to: trip.targetCurrency)
            try await fxQuoteCache?.save(
                rate: rate,
                from: trip.baseCurrency,
                to: trip.targetCurrency,
                quotedAt: now
            )
            return TripFxQuote(
                baseCurrency: trip.baseCurrency,
                targetCurrency: trip.targetCurrency,
                rate: rate,
                quotedAt: now,
                source: .live
            )
        } catch {
            if let cached = try await fxQuoteCache?.load(from: trip.baseCurrency, to: trip.targetCurrency) {
                return TripFxQuote(
                    baseCurrency: trip.baseCurrency,
                    targetCurrency: trip.targetCurrency,
                    rate: cached.rate,
                    quotedAt: cached.quotedAt,
                    source: .cached
                )
            }
            throw error
        }
    }
}
