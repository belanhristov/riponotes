import Foundation
import RipoDomain

public struct ReminderCalendarBindingResult: Sendable {
    public var reminder: Reminder?
    public var calendarLink: CalendarLink?

    public init(reminder: Reminder?, calendarLink: CalendarLink?) {
        self.reminder = reminder
        self.calendarLink = calendarLink
    }
}

public struct ReminderCalendarService: Sendable {
    private let reminderRepository: ReminderRepository
    private let reminderScheduler: ReminderScheduler
    private let calendarLinkRepository: CalendarLinkRepository
    private let calendarEventService: CalendarEventService

    public init(
        reminderRepository: ReminderRepository,
        reminderScheduler: ReminderScheduler,
        calendarLinkRepository: CalendarLinkRepository,
        calendarEventService: CalendarEventService
    ) {
        self.reminderRepository = reminderRepository
        self.reminderScheduler = reminderScheduler
        self.calendarLinkRepository = calendarLinkRepository
        self.calendarEventService = calendarEventService
    }

    public func bindNote(
        note: Note,
        startAt: Date,
        endAt: Date,
        provider: CalendarProvider = .apple,
        addReminder: Bool = true,
        addCalendarEvent: Bool = true,
        reminderType: ReminderType = .reminder,
        reminderPriority: ReminderPriority = .followUp,
        repeatRule: String? = nil
    ) async throws -> ReminderCalendarBindingResult {
        if endAt <= startAt {
            throw ReminderCalendarServiceError.invalidTimeRange
        }

        var boundReminder: Reminder?
        var boundLink: CalendarLink?

        if addReminder {
            let reminder = Reminder(
                noteId: note.id,
                type: reminderType,
                triggerAt: startAt,
                repeatRule: repeatRule,
                priority: reminderPriority,
                isEnabled: true
            )
            try await reminderRepository.upsert(reminder)
            try await reminderScheduler.schedule(reminder)
            boundReminder = reminder
        }

        if addCalendarEvent {
            let eventId = try await calendarEventService.createOrUpdateEvent(
                title: note.title,
                notes: note.plainTextBody,
                startAt: startAt,
                endAt: endAt,
                provider: provider
            )

            let link = CalendarLink(
                noteId: note.id,
                provider: provider,
                externalEventId: eventId,
                eventTitleSnapshot: note.title,
                startAt: startAt,
                endAt: endAt
            )
            try await calendarLinkRepository.upsert(link)
            boundLink = link
        }

        return ReminderCalendarBindingResult(reminder: boundReminder, calendarLink: boundLink)
    }
}

public enum ReminderCalendarServiceError: Error {
    case invalidTimeRange
}
