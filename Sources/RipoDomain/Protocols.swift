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

public protocol AttachmentRepository: Sendable {
    func upsert(_ attachment: Attachment) async throws
    func delete(attachmentId: UUID) async throws
    func attachments(ownerType: AttachmentOwnerType, ownerId: UUID) async throws -> [Attachment]
    func attachment(by id: UUID) async throws -> Attachment?
}

public protocol SecureStore: Sendable {
    func setString(_ value: String, for key: String) async throws
    func string(for key: String) async throws -> String?
    func setData(_ value: Data, for key: String) async throws
    func data(for key: String) async throws -> Data?
    func removeValue(for key: String) async throws
}

public protocol AppAuthenticator: Sendable {
    func authenticate(reason: String) async throws -> Bool
}

public protocol WeatherProvider: Sendable {
    func currentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
}

public protocol PlaceContextProvider: Sendable {
    func currentPlaceContext() async throws -> PlaceContext
}

public protocol SyncEngine: Sendable {
    func enqueue(_ job: SyncJob) async throws
    func pendingJobs() async throws -> [SyncJob]
    func markProcessed(_ jobId: UUID) async throws
}
