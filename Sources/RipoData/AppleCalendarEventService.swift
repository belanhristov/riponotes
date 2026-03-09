import Foundation
import RipoDomain

#if canImport(EventKit)
import EventKit

public enum AppleCalendarEventServiceError: Error {
    case unsupportedProvider
    case calendarUnavailable
}

public actor AppleCalendarEventService: CalendarEventService {
    private let store = EKEventStore()

    public init() {}

    public func createOrUpdateEvent(
        title: String,
        notes: String,
        startAt: Date,
        endAt: Date,
        provider: CalendarProvider
    ) async throws -> String {
        guard provider == .apple else {
            throw AppleCalendarEventServiceError.unsupportedProvider
        }

        try await requestAccessIfNeeded()

        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.startDate = startAt
        event.endDate = endAt
        event.calendar = store.defaultCalendarForNewEvents

        guard event.calendar != nil else {
            throw AppleCalendarEventServiceError.calendarUnavailable
        }

        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    private func requestAccessIfNeeded() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion: @Sendable (Bool, Error?) -> Void = { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if granted {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: CocoaError(.userCancelled))
                }
            }

            if #available(macOS 14.0, iOS 17.0, *) {
                store.requestFullAccessToEvents(completion: completion)
            } else {
                store.requestAccess(to: .event, completion: completion)
            }
        }
    }
}

#endif
