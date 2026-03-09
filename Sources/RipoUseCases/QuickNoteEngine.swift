import Foundation
import RipoDomain

public struct QuickNoteInput: Sendable {
    public var ownerUserId: UUID
    public var text: String
    public var source: NoteSource
    public var folderId: UUID?

    public init(ownerUserId: UUID, text: String, source: NoteSource, folderId: UUID? = nil) {
        self.ownerUserId = ownerUserId
        self.text = text
        self.source = source
        self.folderId = folderId
    }
}

public struct QuickNoteEngine: Sendable {
    private let noteRepository: NoteRepository
    private let syncEngine: SyncEngine

    public init(noteRepository: NoteRepository, syncEngine: SyncEngine) {
        self.noteRepository = noteRepository
        self.syncEngine = syncEngine
    }

    @discardableResult
    public func createNote(_ input: QuickNoteInput, now: Date = .now) async throws -> Note {
        let compact = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = compact.split(separator: "\n").first.map(String.init) ?? "Untitled"

        let note = Note(
            ownerUserId: input.ownerUserId,
            title: String(title.prefix(80)),
            plainTextBody: compact,
            folderId: input.folderId,
            source: input.source,
            syncState: .pending,
            createdAt: now,
            updatedAt: now
        )

        try await noteRepository.create(note)
        try await syncEngine.enqueue(
            SyncJob(entityType: "note", entityId: note.id, operation: .create, enqueuedAt: now)
        )
        return note
    }
}
