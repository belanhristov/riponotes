import Foundation

public enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
}

public enum NoteSource: String, Codable, Sendable {
    case manual
    case widget
    case siri
    case mail
    case shared
}

public enum NoteStatus: String, Codable, Sendable {
    case active
    case archived
    case deleted
}

public enum NoteBlockType: String, Codable, Sendable {
    case paragraph
    case checklist
    case heading
    case quote
}

public enum ReminderType: String, Codable, Sendable {
    case reminder
    case alarm
    case push
}

public enum ReminderPriority: String, Codable, Sendable {
    case silent
    case critical
    case followUp
}

public enum LocationTriggerType: String, Codable, Sendable {
    case onEnter
    case onExit
}

public enum SyncState: String, Codable, Sendable {
    case synced
    case pending
    case failed
}

public enum CalendarProvider: String, Codable, Sendable {
    case apple
    case outlook
}

public enum TemplateScope: String, Codable, Sendable, CaseIterable {
    case note
    case journal
}

public enum TemplateType: String, Codable, Sendable, CaseIterable {
    case meeting
    case shopping
    case project
    case daily
    case idea
    case custom
}

public enum AttachmentType: String, Codable, Sendable {
    case image
    case audio
    case file
    case mail
}

public enum AttachmentOwnerType: String, Codable, Sendable {
    case note
    case template
}

public enum WeatherCondition: String, Codable, Sendable, CaseIterable {
    case sunny
    case cloudy
    case rainy
    case snowy
    case windy
    case unknown
}

public enum TripSegmentType: String, Codable, Sendable, CaseIterable {
    case flight
    case hotel
    case transport
    case activity
}

public enum TripChecklistCategory: String, Codable, Sendable, CaseIterable {
    case documents
    case booking
    case health
    case finance
    case misc
}

public enum PackingCategory: String, Codable, Sendable, CaseIterable {
    case clothes
    case tech
    case medicine
    case documents
    case custom
}

public enum TravelActivity: String, Codable, Sendable, CaseIterable {
    case beach
    case business
    case cityWalk
    case hiking
    case nightlife
    case winterSports
}

public struct User: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var authProvider: AuthProvider
    public var displayName: String
    public var email: String
    public var localeIdentifier: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        authProvider: AuthProvider,
        displayName: String,
        email: String,
        localeIdentifier: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.authProvider = authProvider
        self.displayName = displayName
        self.email = email
        self.localeIdentifier = localeIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Note: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var ownerUserId: UUID
    public var title: String
    public var plainTextBody: String
    public var folderId: UUID?
    public var isPinned: Bool
    public var status: NoteStatus
    public var source: NoteSource
    public var tags: Set<String>
    public var syncState: SyncState
    public var version: Int
    public var lastSyncedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        ownerUserId: UUID,
        title: String,
        plainTextBody: String,
        folderId: UUID? = nil,
        isPinned: Bool = false,
        status: NoteStatus = .active,
        source: NoteSource,
        tags: Set<String> = [],
        syncState: SyncState = .pending,
        version: Int = 1,
        lastSyncedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.title = title
        self.plainTextBody = plainTextBody
        self.folderId = folderId
        self.isPinned = isPinned
        self.status = status
        self.source = source
        self.tags = tags
        self.syncState = syncState
        self.version = version
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

public struct NoteBlock: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID
    public var type: NoteBlockType
    public var position: Int
    public var payloadJSON: String

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        type: NoteBlockType,
        position: Int,
        payloadJSON: String
    ) {
        self.id = id
        self.noteId = noteId
        self.type = type
        self.position = position
        self.payloadJSON = payloadJSON
    }
}

public struct Reminder: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID
    public var type: ReminderType
    public var triggerAt: Date
    public var repeatRule: String?
    public var priority: ReminderPriority
    public var isEnabled: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        type: ReminderType,
        triggerAt: Date,
        repeatRule: String? = nil,
        priority: ReminderPriority = .silent,
        isEnabled: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.noteId = noteId
        self.type = type
        self.triggerAt = triggerAt
        self.repeatRule = repeatRule
        self.priority = priority
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct RipoList: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID?
    public var title: String
    public var templateType: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        noteId: UUID? = nil,
        title: String,
        templateType: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.noteId = noteId
        self.title = title
        self.templateType = templateType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ListItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var listId: UUID
    public var text: String
    public var isDone: Bool
    public var order: Int
    public var dueAt: Date?

    public init(
        id: UUID = UUID(),
        listId: UUID,
        text: String,
        isDone: Bool = false,
        order: Int,
        dueAt: Date? = nil
    ) {
        self.id = id
        self.listId = listId
        self.text = text
        self.isDone = isDone
        self.order = order
        self.dueAt = dueAt
    }
}

public struct ContactLink: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID
    public var contactIdentifier: String
    public var displayNameSnapshot: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        contactIdentifier: String,
        displayNameSnapshot: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.noteId = noteId
        self.contactIdentifier = contactIdentifier
        self.displayNameSnapshot = displayNameSnapshot
        self.createdAt = createdAt
    }
}

public struct LocationLink: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var label: String
    public var triggerType: LocationTriggerType

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        label: String,
        triggerType: LocationTriggerType
    ) {
        self.id = id
        self.noteId = noteId
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.label = label
        self.triggerType = triggerType
    }
}

public struct CalendarLink: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var noteId: UUID
    public var provider: CalendarProvider
    public var externalEventId: String
    public var eventTitleSnapshot: String
    public var startAt: Date
    public var endAt: Date
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        noteId: UUID,
        provider: CalendarProvider,
        externalEventId: String,
        eventTitleSnapshot: String,
        startAt: Date,
        endAt: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.noteId = noteId
        self.provider = provider
        self.externalEventId = externalEventId
        self.eventTitleSnapshot = eventTitleSnapshot
        self.startAt = startAt
        self.endAt = endAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TemplateDefinition: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var ownerUserId: UUID
    public var name: String
    public var scope: TemplateScope
    public var type: TemplateType
    public var titleTemplate: String
    public var bodyTemplate: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        ownerUserId: UUID,
        name: String,
        scope: TemplateScope,
        type: TemplateType,
        titleTemplate: String,
        bodyTemplate: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.name = name
        self.scope = scope
        self.type = type
        self.titleTemplate = titleTemplate
        self.bodyTemplate = bodyTemplate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Attachment: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var ownerType: AttachmentOwnerType
    public var ownerId: UUID
    public var type: AttachmentType
    public var localPath: String
    public var remoteURL: String?
    public var metadataJSON: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        ownerType: AttachmentOwnerType,
        ownerId: UUID,
        type: AttachmentType,
        localPath: String,
        remoteURL: String? = nil,
        metadataJSON: String = "{}",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerType = ownerType
        self.ownerId = ownerId
        self.type = type
        self.localPath = localPath
        self.remoteURL = remoteURL
        self.metadataJSON = metadataJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct WeatherSnapshot: Codable, Sendable, Equatable {
    public var condition: WeatherCondition
    public var temperatureCelsius: Double
    public var feelsLikeCelsius: Double
    public var capturedAt: Date

    public init(
        condition: WeatherCondition,
        temperatureCelsius: Double,
        feelsLikeCelsius: Double,
        capturedAt: Date = .now
    ) {
        self.condition = condition
        self.temperatureCelsius = temperatureCelsius
        self.feelsLikeCelsius = feelsLikeCelsius
        self.capturedAt = capturedAt
    }
}

public struct PlaceContext: Codable, Sendable, Equatable {
    public var latitude: Double
    public var longitude: Double
    public var label: String
    public var distanceToBeachMeters: Double?

    public init(latitude: Double, longitude: Double, label: String, distanceToBeachMeters: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.label = label
        self.distanceToBeachMeters = distanceToBeachMeters
    }
}

public struct Trip: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var ownerUserId: UUID
    public var title: String
    public var origin: String
    public var destination: String
    public var startDate: Date
    public var endDate: Date
    public var baseCurrency: String
    public var targetCurrency: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        ownerUserId: UUID,
        title: String,
        origin: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        baseCurrency: String,
        targetCurrency: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.title = title
        self.origin = origin
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.baseCurrency = baseCurrency
        self.targetCurrency = targetCurrency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TripSegment: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var tripId: UUID
    public var type: TripSegmentType
    public var startAt: Date
    public var endAt: Date
    public var providerName: String
    public var confirmationCode: String
    public var notes: String

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        type: TripSegmentType,
        startAt: Date,
        endAt: Date,
        providerName: String,
        confirmationCode: String,
        notes: String = ""
    ) {
        self.id = id
        self.tripId = tripId
        self.type = type
        self.startAt = startAt
        self.endAt = endAt
        self.providerName = providerName
        self.confirmationCode = confirmationCode
        self.notes = notes
    }
}

public struct TripChecklistItem: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var tripId: UUID
    public var category: TripChecklistCategory
    public var text: String
    public var isDone: Bool
    public var isCritical: Bool
    public var dueAt: Date?

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        category: TripChecklistCategory,
        text: String,
        isDone: Bool = false,
        isCritical: Bool = false,
        dueAt: Date? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.category = category
        self.text = text
        self.isDone = isDone
        self.isCritical = isCritical
        self.dueAt = dueAt
    }
}

public struct PackingItem: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var tripId: UUID
    public var category: PackingCategory
    public var text: String
    public var quantity: Int
    public var isDone: Bool
    public var isCritical: Bool

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        category: PackingCategory,
        text: String,
        quantity: Int = 1,
        isDone: Bool = false,
        isCritical: Bool = false
    ) {
        self.id = id
        self.tripId = tripId
        self.category = category
        self.text = text
        self.quantity = quantity
        self.isDone = isDone
        self.isCritical = isCritical
    }
}

public struct TripBudgetEstimate: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var tripId: UUID
    public var estimatedTotal: Double
    public var currency: String
    public var dailyEstimate: Double
    public var fxRateUsed: Double
    public var confidence: Double
    public var generatedAt: Date

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        estimatedTotal: Double,
        currency: String,
        dailyEstimate: Double,
        fxRateUsed: Double,
        confidence: Double,
        generatedAt: Date = .now
    ) {
        self.id = id
        self.tripId = tripId
        self.estimatedTotal = estimatedTotal
        self.currency = currency
        self.dailyEstimate = dailyEstimate
        self.fxRateUsed = fxRateUsed
        self.confidence = confidence
        self.generatedAt = generatedAt
    }
}

public enum FxQuoteSource: String, Codable, Sendable, Equatable {
    case live
    case cached
}

public struct TripExpenseProfile: Codable, Sendable, Equatable {
    public var breakfastCost: Double
    public var lunchCost: Double
    public var dinnerCost: Double
    public var drinksCost: Double
    public var transportCost: Double
    public var miscCost: Double

    public init(
        breakfastCost: Double = 0,
        lunchCost: Double = 0,
        dinnerCost: Double = 0,
        drinksCost: Double = 0,
        transportCost: Double = 0,
        miscCost: Double = 0
    ) {
        self.breakfastCost = breakfastCost
        self.lunchCost = lunchCost
        self.dinnerCost = dinnerCost
        self.drinksCost = drinksCost
        self.transportCost = transportCost
        self.miscCost = miscCost
    }

    public var dailyTotal: Double {
        breakfastCost + lunchCost + dinnerCost + drinksCost + transportCost + miscCost
    }
}

public struct SyncJob: Identifiable, Codable, Sendable, Equatable {
    public enum Operation: String, Codable, Sendable {
        case create
        case update
        case delete
    }

    public let id: UUID
    public var entityType: String
    public var entityId: UUID
    public var operation: Operation
    public var enqueuedAt: Date

    public init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        operation: Operation,
        enqueuedAt: Date = .now
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.enqueuedAt = enqueuedAt
    }
}
