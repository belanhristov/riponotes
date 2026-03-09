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
