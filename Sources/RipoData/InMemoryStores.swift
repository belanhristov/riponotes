import Foundation
import RipoDomain

public enum InMemoryError: Error {
    case alreadyExists
}

public actor InMemoryNoteRepository: NoteRepository {
    private var notes: [UUID: Note] = [:]

    public init() {}

    public func create(_ note: Note) async throws {
        guard notes[note.id] == nil else {
            throw InMemoryError.alreadyExists
        }
        notes[note.id] = note
    }

    public func update(_ note: Note) async throws {
        notes[note.id] = note
    }

    public func softDelete(noteId: UUID, deletedAt: Date) async throws {
        guard var note = notes[noteId] else { return }
        note.status = .deleted
        note.deletedAt = deletedAt
        note.updatedAt = deletedAt
        note.version += 1
        note.syncState = .pending
        notes[note.id] = note
    }

    public func note(by id: UUID) async throws -> Note? {
        notes[id]
    }

    public func inboxNotes(ownerUserId: UUID) async throws -> [Note] {
        notes.values
            .filter { $0.ownerUserId == ownerUserId && $0.folderId == nil && $0.status == .active }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    public func search(ownerUserId: UUID, query: String) async throws -> [Note] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        return notes.values
            .filter {
                $0.ownerUserId == ownerUserId
                    && $0.status == .active
                    && (
                        $0.title.lowercased().contains(q)
                            || $0.plainTextBody.lowercased().contains(q)
                            || $0.tags.contains(where: { $0.lowercased().contains(q) })
                    )
            }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

public actor InMemoryReminderRepository: ReminderRepository {
    private var reminders: [UUID: Reminder] = [:]

    public init() {}

    public func upsert(_ reminder: Reminder) async throws {
        reminders[reminder.id] = reminder
    }

    public func reminders(for noteId: UUID) async throws -> [Reminder] {
        reminders.values
            .filter { $0.noteId == noteId }
            .sorted(by: { $0.triggerAt < $1.triggerAt })
    }
}

public actor InMemoryReminderScheduler: ReminderScheduler {
    private var scheduled: [UUID: Reminder] = [:]

    public init() {}

    public func schedule(_ reminder: Reminder) async throws {
        scheduled[reminder.id] = reminder
    }

    public func cancel(reminderId: UUID) async throws {
        scheduled.removeValue(forKey: reminderId)
    }

    public func scheduledReminder(reminderId: UUID) async -> Reminder? {
        scheduled[reminderId]
    }
}

public actor InMemorySyncEngine: SyncEngine {
    private var queue: [SyncJob] = []

    public init() {}

    public func enqueue(_ job: SyncJob) async throws {
        queue.append(job)
    }

    public func pendingJobs() async throws -> [SyncJob] {
        queue
    }

    public func markProcessed(_ jobId: UUID) async throws {
        queue.removeAll(where: { $0.id == jobId })
    }
}

public actor InMemoryCalendarLinkRepository: CalendarLinkRepository {
    private var links: [UUID: CalendarLink] = [:]

    public init() {}

    public func upsert(_ link: CalendarLink) async throws {
        links[link.id] = link
    }

    public func links(for noteId: UUID) async throws -> [CalendarLink] {
        links.values
            .filter { $0.noteId == noteId }
            .sorted(by: { $0.startAt < $1.startAt })
    }
}

public actor InMemoryCalendarEventService: CalendarEventService {
    private var events: [String: (title: String, startAt: Date, endAt: Date, provider: CalendarProvider)] = [:]

    public init() {}

    public func createOrUpdateEvent(
        title: String,
        notes _: String,
        startAt: Date,
        endAt: Date,
        provider: CalendarProvider
    ) async throws -> String {
        let id = "\(provider.rawValue)-\(UUID().uuidString)"
        events[id] = (title: title, startAt: startAt, endAt: endAt, provider: provider)
        return id
    }

    public func event(id: String) async -> (title: String, startAt: Date, endAt: Date, provider: CalendarProvider)? {
        events[id]
    }
}

public actor InMemoryTemplateRepository: TemplateRepository {
    private var templatesById: [UUID: TemplateDefinition] = [:]

    public init() {}

    public func upsert(_ template: TemplateDefinition) async throws {
        templatesById[template.id] = template
    }

    public func template(by id: UUID) async throws -> TemplateDefinition? {
        templatesById[id]
    }

    public func templates(ownerUserId: UUID, scope: TemplateScope?) async throws -> [TemplateDefinition] {
        templatesById.values
            .filter { template in
                template.ownerUserId == ownerUserId && (scope == nil || template.scope == scope)
            }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}

public actor InMemoryAttachmentRepository: AttachmentRepository {
    private var attachmentsById: [UUID: Attachment] = [:]

    public init() {}

    public func upsert(_ attachment: Attachment) async throws {
        attachmentsById[attachment.id] = attachment
    }

    public func delete(attachmentId: UUID) async throws {
        attachmentsById.removeValue(forKey: attachmentId)
    }

    public func attachments(ownerType: AttachmentOwnerType, ownerId: UUID) async throws -> [Attachment] {
        attachmentsById.values
            .filter { $0.ownerType == ownerType && $0.ownerId == ownerId }
            .sorted(by: { $0.createdAt < $1.createdAt })
    }

    public func attachment(by id: UUID) async throws -> Attachment? {
        attachmentsById[id]
    }
}

public actor InMemorySecureStore: SecureStore {
    private var stringValues: [String: String] = [:]
    private var dataValues: [String: Data] = [:]

    public init() {}

    public func setString(_ value: String, for key: String) async throws {
        stringValues[key] = value
    }

    public func string(for key: String) async throws -> String? {
        stringValues[key]
    }

    public func setData(_ value: Data, for key: String) async throws {
        dataValues[key] = value
    }

    public func data(for key: String) async throws -> Data? {
        dataValues[key]
    }

    public func removeValue(for key: String) async throws {
        stringValues.removeValue(forKey: key)
        dataValues.removeValue(forKey: key)
    }
}

public actor InMemoryAppAuthenticator: AppAuthenticator {
    private var nextResult: Bool

    public init(nextResult: Bool = true) {
        self.nextResult = nextResult
    }

    public func authenticate(reason _: String) async throws -> Bool {
        nextResult
    }

    public func setNextResult(_ value: Bool) async {
        nextResult = value
    }
}

public actor InMemoryWeatherProvider: WeatherProvider {
    private var snapshot: WeatherSnapshot

    public init(snapshot: WeatherSnapshot) {
        self.snapshot = snapshot
    }

    public func currentWeather(latitude _: Double, longitude _: Double) async throws -> WeatherSnapshot {
        snapshot
    }

    public func setSnapshot(_ snapshot: WeatherSnapshot) async {
        self.snapshot = snapshot
    }
}

public actor InMemoryPlaceContextProvider: PlaceContextProvider {
    private var context: PlaceContext

    public init(context: PlaceContext) {
        self.context = context
    }

    public func currentPlaceContext() async throws -> PlaceContext {
        context
    }

    public func setContext(_ context: PlaceContext) async {
        self.context = context
    }
}

public actor InMemoryCurrencyRateProvider: CurrencyRateProvider {
    private var rates: [String: Double]

    public init(rates: [String: Double]) {
        self.rates = rates
    }

    public func rate(from baseCurrency: String, to targetCurrency: String) async throws -> Double {
        if baseCurrency.uppercased() == targetCurrency.uppercased() {
            return 1
        }
        let key = "\(baseCurrency.uppercased())_\(targetCurrency.uppercased())"
        return rates[key] ?? 1
    }

    public func setRate(from baseCurrency: String, to targetCurrency: String, value: Double) async {
        rates["\(baseCurrency.uppercased())_\(targetCurrency.uppercased())"] = value
    }
}

public actor InMemoryTripRepository: TripRepository {
    private var tripsById: [UUID: Trip] = [:]
    private var segmentsById: [UUID: TripSegment] = [:]
    private var checklistById: [UUID: TripChecklistItem] = [:]
    private var packingById: [UUID: PackingItem] = [:]
    private var budgetByTripId: [UUID: TripBudgetEstimate] = [:]

    public init() {}

    public func upsertTrip(_ trip: Trip) async throws {
        tripsById[trip.id] = trip
    }

    public func trip(by id: UUID) async throws -> Trip? {
        tripsById[id]
    }

    public func trips(ownerUserId: UUID) async throws -> [Trip] {
        tripsById.values
            .filter { $0.ownerUserId == ownerUserId }
            .sorted(by: { $0.startDate < $1.startDate })
    }

    public func upsertSegment(_ segment: TripSegment) async throws {
        segmentsById[segment.id] = segment
    }

    public func segments(tripId: UUID) async throws -> [TripSegment] {
        segmentsById.values
            .filter { $0.tripId == tripId }
            .sorted(by: { $0.startAt < $1.startAt })
    }

    public func upsertChecklistItem(_ item: TripChecklistItem) async throws {
        checklistById[item.id] = item
    }

    public func checklistItems(tripId: UUID) async throws -> [TripChecklistItem] {
        checklistById.values
            .filter { $0.tripId == tripId }
            .sorted(by: { $0.text < $1.text })
    }

    public func upsertPackingItem(_ item: PackingItem) async throws {
        packingById[item.id] = item
    }

    public func packingItems(tripId: UUID) async throws -> [PackingItem] {
        packingById.values
            .filter { $0.tripId == tripId }
            .sorted(by: { $0.text < $1.text })
    }

    public func upsertBudgetEstimate(_ estimate: TripBudgetEstimate) async throws {
        budgetByTripId[estimate.tripId] = estimate
    }

    public func budgetEstimate(tripId: UUID) async throws -> TripBudgetEstimate? {
        budgetByTripId[tripId]
    }
}
