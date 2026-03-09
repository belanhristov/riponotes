import Foundation
import RipoDomain

public struct ConvertNoteService: Sendable {
    private let reminderRepository: ReminderRepository
    private let reminderScheduler: ReminderScheduler
    private let listRepository: ListRepository
    private let contactLinkRepository: ContactLinkRepository
    private let locationLinkRepository: LocationLinkRepository

    public init(
        reminderRepository: ReminderRepository,
        reminderScheduler: ReminderScheduler,
        listRepository: ListRepository,
        contactLinkRepository: ContactLinkRepository,
        locationLinkRepository: LocationLinkRepository
    ) {
        self.reminderRepository = reminderRepository
        self.reminderScheduler = reminderScheduler
        self.listRepository = listRepository
        self.contactLinkRepository = contactLinkRepository
        self.locationLinkRepository = locationLinkRepository
    }

    public func convertToReminder(
        noteId: UUID,
        triggerAt: Date,
        type: ReminderType = .reminder,
        priority: ReminderPriority = .followUp,
        repeatRule: String? = nil
    ) async throws -> Reminder {
        var reminder = Reminder(
            noteId: noteId,
            type: type,
            triggerAt: triggerAt,
            repeatRule: repeatRule,
            priority: priority,
            isEnabled: true
        )
        reminder.updatedAt = .now

        try await reminderRepository.upsert(reminder)
        try await reminderScheduler.schedule(reminder)
        return reminder
    }

    public func convertToList(
        noteId: UUID,
        title: String,
        templateType: String = "custom",
        items: [String] = [],
        now: Date = .now
    ) async throws -> RipoList {
        var list = RipoList(
            noteId: noteId,
            title: title,
            templateType: templateType,
            createdAt: now,
            updatedAt: now
        )
        list.updatedAt = now
        try await listRepository.upsertList(list)

        for (index, text) in items.enumerated() where !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ListItem(
                listId: list.id,
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                isDone: false,
                order: index
            )
            try await listRepository.upsertItem(item)
        }
        return list
    }

    public func convertToContactLink(
        noteId: UUID,
        contactIdentifier: String,
        displayNameSnapshot: String,
        now: Date = .now
    ) async throws -> ContactLink {
        let link = ContactLink(
            noteId: noteId,
            contactIdentifier: contactIdentifier,
            displayNameSnapshot: displayNameSnapshot,
            createdAt: now
        )
        try await contactLinkRepository.upsert(link)
        return link
    }

    public func convertToLocationLink(
        noteId: UUID,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        label: String,
        triggerType: LocationTriggerType = .onEnter
    ) async throws -> LocationLink {
        let link = LocationLink(
            noteId: noteId,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            label: label,
            triggerType: triggerType
        )
        try await locationLinkRepository.upsert(link)
        return link
    }
}
