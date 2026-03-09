import Foundation
import RipoDomain

public enum TripAlertServiceError: Error {
    case tripNotFound
    case invalidJourneyHour
}

public struct TripOpenRefreshSnapshot: Sendable, Equatable {
    public var fxQuote: TripFxQuote
    public var weather: WeatherSnapshot?

    public init(fxQuote: TripFxQuote, weather: WeatherSnapshot?) {
        self.fxQuote = fxQuote
        self.weather = weather
    }
}

public struct TripAlertService: Sendable {
    private let tripRepository: TripRepository
    private let reminderRepository: ReminderRepository
    private let reminderScheduler: ReminderScheduler
    private let planner: TravelPlannerService

    public init(
        tripRepository: TripRepository,
        reminderRepository: ReminderRepository,
        reminderScheduler: ReminderScheduler,
        planner: TravelPlannerService
    ) {
        self.tripRepository = tripRepository
        self.reminderRepository = reminderRepository
        self.reminderScheduler = reminderScheduler
        self.planner = planner
    }

    public func schedulePreTripChecks(tripId: UUID, now: Date = .now) async throws -> [Reminder] {
        guard let trip = try await tripRepository.trip(by: tripId) else {
            throw TripAlertServiceError.tripNotFound
        }

        let reminderTimes = [
            trip.startDate.addingTimeInterval(-(3 * 24 * 60 * 60)),
            trip.startDate.addingTimeInterval(-(24 * 60 * 60)),
        ].filter { $0 > now }

        var reminders: [Reminder] = []
        for triggerAt in reminderTimes {
            let reminder = Reminder(
                noteId: trip.id,
                type: .push,
                triggerAt: triggerAt,
                repeatRule: nil,
                priority: .followUp,
                isEnabled: true,
                createdAt: now,
                updatedAt: now
            )
            try await reminderRepository.upsert(reminder)
            try await reminderScheduler.schedule(reminder)
            reminders.append(reminder)
        }
        return reminders
    }

    public func scheduleJourneyPrompts(
        tripId: UUID,
        localHour: Int = 9,
        now: Date = .now
    ) async throws -> [Reminder] {
        guard let trip = try await tripRepository.trip(by: tripId) else {
            throw TripAlertServiceError.tripNotFound
        }
        guard (0...23).contains(localHour) else {
            throw TripAlertServiceError.invalidJourneyHour
        }

        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: max(now, trip.startDate))
        let endDay = calendar.startOfDay(for: trip.endDate)
        guard startDay <= endDay else { return [] }

        var cursor = startDay
        var reminders: [Reminder] = []
        while cursor <= endDay {
            guard let triggerAt = calendar.date(bySettingHour: localHour, minute: 0, second: 0, of: cursor) else {
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(24 * 60 * 60)
                continue
            }
            if triggerAt > now {
                let reminder = Reminder(
                    noteId: trip.id,
                    type: .push,
                    triggerAt: triggerAt,
                    repeatRule: nil,
                    priority: .followUp,
                    isEnabled: true,
                    createdAt: now,
                    updatedAt: now
                )
                try await reminderRepository.upsert(reminder)
                try await reminderScheduler.schedule(reminder)
                reminders.append(reminder)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(24 * 60 * 60)
        }

        return reminders
    }

    public func refreshOnTripOpen(tripId: UUID) async throws -> TripOpenRefreshSnapshot {
        guard let trip = try await tripRepository.trip(by: tripId) else {
            throw TripAlertServiceError.tripNotFound
        }
        let fx = try await planner.currentFxQuote(tripId: tripId)
        let weather: WeatherSnapshot?
        if let lat = trip.destinationLatitude,
           let lon = trip.destinationLongitude
        {
            weather = try await planner.weatherSummaryForTripDestination(
                tripId: tripId,
                latitude: lat,
                longitude: lon
            )
        } else {
            weather = nil
        }
        return TripOpenRefreshSnapshot(fxQuote: fx, weather: weather)
    }
}
