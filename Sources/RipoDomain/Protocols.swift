import Foundation

public protocol NoteRepository: Sendable {
    func create(_ note: Note) async throws
    func update(_ note: Note) async throws
    func softDelete(noteId: UUID, deletedAt: Date) async throws
    func note(by id: UUID) async throws -> Note?
    func activeNotes(ownerUserId: UUID) async throws -> [Note]
    func inboxNotes(ownerUserId: UUID) async throws -> [Note]
    func search(ownerUserId: UUID, query: String) async throws -> [Note]
}

public protocol UserProfileRepository: Sendable {
    func upsert(_ profile: UserProfile) async throws
    func profile(userId: UUID) async throws -> UserProfile?
    func profile(username: String) async throws -> UserProfile?
}

public protocol UserBadgeRepository: Sendable {
    func upsert(_ badge: UserBadge) async throws
    func badges(userId: UUID) async throws -> [UserBadge]
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
    func allAttachments() async throws -> [Attachment]
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

public protocol CurrencyRateProvider: Sendable {
    func rate(from baseCurrency: String, to targetCurrency: String) async throws -> Double
}

public protocol FxQuoteCache: Sendable {
    func save(rate: Double, from baseCurrency: String, to targetCurrency: String, quotedAt: Date) async throws
    func load(from baseCurrency: String, to targetCurrency: String) async throws -> (rate: Double, quotedAt: Date)?
}

public protocol TripRepository: Sendable {
    func upsertTrip(_ trip: Trip) async throws
    func trip(by id: UUID) async throws -> Trip?
    func trips(ownerUserId: UUID) async throws -> [Trip]

    func upsertSegment(_ segment: TripSegment) async throws
    func segments(tripId: UUID) async throws -> [TripSegment]

    func upsertChecklistItem(_ item: TripChecklistItem) async throws
    func checklistItems(tripId: UUID) async throws -> [TripChecklistItem]

    func upsertPackingItem(_ item: PackingItem) async throws
    func packingItems(tripId: UUID) async throws -> [PackingItem]

    func upsertBudgetEstimate(_ estimate: TripBudgetEstimate) async throws
    func budgetEstimate(tripId: UUID) async throws -> TripBudgetEstimate?
}

public protocol JourneyRepository: Sendable {
    func upsertEntry(_ entry: JourneyEntry) async throws
    func entries(tripId: UUID) async throws -> [JourneyEntry]
    func entry(by id: UUID) async throws -> JourneyEntry?

    func upsertPlaceReview(_ review: PlaceReview) async throws
    func placeReviews(tripId: UUID) async throws -> [PlaceReview]
    func placeReviews(locationTag: String) async throws -> [PlaceReview]
}

public protocol SocialRepository: Sendable {
    func upsertPost(_ post: SocialPost) async throws
    func post(by id: UUID) async throws -> SocialPost?
    func posts(authorUserId: UUID?) async throws -> [SocialPost]
    func posts(tag: String) async throws -> [SocialPost]

    func upsertComment(_ comment: SocialComment) async throws
    func comments(postId: UUID) async throws -> [SocialComment]

    func upsertReaction(_ reaction: SocialReaction) async throws
    func reactions(postId: UUID) async throws -> [SocialReaction]

    func upsertUserFollow(_ follow: UserFollow) async throws
    func follows(followerUserId: UUID) async throws -> [UserFollow]

    func upsertTagFollow(_ follow: TagFollow) async throws
    func tagFollows(followerUserId: UUID) async throws -> [TagFollow]
}

public protocol SyncEngine: Sendable {
    func enqueue(_ job: SyncJob) async throws
    func pendingJobs() async throws -> [SyncJob]
    func markProcessed(_ jobId: UUID) async throws
}
