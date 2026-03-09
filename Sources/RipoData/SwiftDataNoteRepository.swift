import Foundation
import RipoDomain

#if canImport(SwiftData)
import SwiftData

@Model
final class NoteRecord {
    @Attribute(.unique) var id: UUID
    var ownerUserId: UUID
    var title: String
    var plainTextBody: String
    var folderId: UUID?
    var isPinned: Bool
    var statusRaw: String
    var sourceRaw: String
    var tags: [String]
    var syncStateRaw: String
    var version: Int
    var lastSyncedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(from note: Note) {
        self.id = note.id
        self.ownerUserId = note.ownerUserId
        self.title = note.title
        self.plainTextBody = note.plainTextBody
        self.folderId = note.folderId
        self.isPinned = note.isPinned
        self.statusRaw = note.status.rawValue
        self.sourceRaw = note.source.rawValue
        self.tags = Array(note.tags)
        self.syncStateRaw = note.syncState.rawValue
        self.version = note.version
        self.lastSyncedAt = note.lastSyncedAt
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
        self.deletedAt = note.deletedAt
    }

    func apply(note: Note) {
        ownerUserId = note.ownerUserId
        title = note.title
        plainTextBody = note.plainTextBody
        folderId = note.folderId
        isPinned = note.isPinned
        statusRaw = note.status.rawValue
        sourceRaw = note.source.rawValue
        tags = Array(note.tags)
        syncStateRaw = note.syncState.rawValue
        version = note.version
        lastSyncedAt = note.lastSyncedAt
        createdAt = note.createdAt
        updatedAt = note.updatedAt
        deletedAt = note.deletedAt
    }

    var asDomain: Note {
        Note(
            id: id,
            ownerUserId: ownerUserId,
            title: title,
            plainTextBody: plainTextBody,
            folderId: folderId,
            isPinned: isPinned,
            status: NoteStatus(rawValue: statusRaw) ?? .active,
            source: NoteSource(rawValue: sourceRaw) ?? .manual,
            tags: Set(tags),
            syncState: SyncState(rawValue: syncStateRaw) ?? .pending,
            version: version,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

public enum SwiftDataRepositoryError: Error {
    case notFound
}

public final class SwiftDataNoteRepository: NoteRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    public init(inMemory: Bool = false) throws {
        let schema = Schema([NoteRecord.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }

    public func create(_ note: Note) async throws {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            context.insert(NoteRecord(from: note))
            try context.save()
        }
    }

    public func update(_ note: Note) async throws {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            guard let record = try fetchRecord(id: note.id, context: context) else {
                throw SwiftDataRepositoryError.notFound
            }
            record.apply(note: note)
            try context.save()
        }
    }

    public func softDelete(noteId: UUID, deletedAt: Date) async throws {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            guard let record = try fetchRecord(id: noteId, context: context) else {
                return
            }

            record.statusRaw = NoteStatus.deleted.rawValue
            record.deletedAt = deletedAt
            record.updatedAt = deletedAt
            record.version += 1
            record.syncStateRaw = SyncState.pending.rawValue
            try context.save()
        }
    }

    public func note(by id: UUID) async throws -> Note? {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            return try fetchRecord(id: id, context: context)?.asDomain
        }
    }

    public func activeNotes(ownerUserId: UUID) async throws -> [Note] {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<NoteRecord>(
                predicate: #Predicate { $0.ownerUserId == ownerUserId },
                sortBy: [SortDescriptor(\NoteRecord.updatedAt, order: .reverse)]
            )
            return try context
                .fetch(descriptor)
                .filter { $0.statusRaw == NoteStatus.active.rawValue }
                .map { $0.asDomain }
        }
    }

    public func inboxNotes(ownerUserId: UUID) async throws -> [Note] {
        try await MainActor.run {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<NoteRecord>(
                predicate: #Predicate { $0.ownerUserId == ownerUserId && $0.folderId == nil },
                sortBy: [SortDescriptor(\NoteRecord.updatedAt, order: .reverse)]
            )
            return try context
                .fetch(descriptor)
                .filter { $0.statusRaw == NoteStatus.active.rawValue }
                .map { $0.asDomain }
        }
    }

    public func search(ownerUserId: UUID, query: String) async throws -> [Note] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        return try await MainActor.run {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<NoteRecord>(
                predicate: #Predicate { $0.ownerUserId == ownerUserId },
                sortBy: [SortDescriptor(\NoteRecord.updatedAt, order: .reverse)]
            )

            return try context
                .fetch(descriptor)
                .filter { $0.statusRaw == NoteStatus.active.rawValue }
                .filter {
                    $0.title.lowercased().contains(q)
                        || $0.plainTextBody.lowercased().contains(q)
                        || $0.tags.contains(where: { $0.lowercased().contains(q) })
                }
                .map { $0.asDomain }
        }
    }

    private func fetchRecord(id: UUID, context: ModelContext) throws -> NoteRecord? {
        let descriptor = FetchDescriptor<NoteRecord>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}

#endif
