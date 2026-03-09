import Foundation

public protocol NoteRepository: Sendable {
    func create(_ note: Note) async throws
    func update(_ note: Note) async throws
    func softDelete(noteId: UUID, deletedAt: Date) async throws
    func note(by id: UUID) async throws -> Note?
    func inboxNotes(ownerUserId: UUID) async throws -> [Note]
    func search(ownerUserId: UUID, query: String) async throws -> [Note]
}

public protocol ReminderRepository: Sendable {
    func upsert(_ reminder: Reminder) async throws
    func reminders(for noteId: UUID) async throws -> [Reminder]
}

public protocol ReminderScheduler: Sendable {
    func schedule(_ reminder: Reminder) async throws
    func cancel(reminderId: UUID) async throws
}

public protocol CalendarLinkRepository: Sendable {
    func upsert(_ link: CalendarLink) async throws
    func links(for noteId: UUID) async throws -> [CalendarLink]
}

public protocol CalendarEventService: Sendable {
    func createOrUpdateEvent(
        title: String,
        notes: String,
        startAt: Date,
        endAt: Date,
        provider: CalendarProvider
    ) async throws -> String
}

public protocol TemplateRepository: Sendable {
    func upsert(_ template: TemplateDefinition) async throws
    func template(by id: UUID) async throws -> TemplateDefinition?
    func templates(ownerUserId: UUID, scope: TemplateScope?) async throws -> [TemplateDefinition]
}

public protocol SyncEngine: Sendable {
    func enqueue(_ job: SyncJob) async throws
    func pendingJobs() async throws -> [SyncJob]
    func markProcessed(_ jobId: UUID) async throws
}
