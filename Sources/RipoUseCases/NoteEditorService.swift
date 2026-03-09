import Foundation
import RipoDomain

public struct NoteEditorService: Sendable {
    private let noteRepository: NoteRepository
    private let syncEngine: SyncEngine

    public init(noteRepository: NoteRepository, syncEngine: SyncEngine) {
        self.noteRepository = noteRepository
        self.syncEngine = syncEngine
    }

    public func createDraft(
        ownerUserId: UUID,
        source: NoteSource = .manual,
        now: Date = .now
    ) async throws -> Note {
        let note = Note(
            ownerUserId: ownerUserId,
            title: "Untitled",
            plainTextBody: "",
            source: source,
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

    public func save(
        noteId: UUID,
        title: String,
        body: String,
        now: Date = .now
    ) async throws -> Note {
        guard var note = try await noteRepository.note(by: noteId) else {
            throw NoteEditorError.noteNotFound
        }

        note.title = normalizedTitle(from: title, body: body)
        note.plainTextBody = body
        note.updatedAt = now
        note.version += 1
        note.syncState = .pending

        try await noteRepository.update(note)
        try await syncEngine.enqueue(
            SyncJob(entityType: "note", entityId: note.id, operation: .update, enqueuedAt: now)
        )
        return note
    }

    private func normalizedTitle(from title: String, body: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return String(trimmedTitle.prefix(80))
        }

        let firstLine = body
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .first
            .map(String.init) ?? "Untitled"

        return String(firstLine.prefix(80))
    }
}

public enum NoteEditorError: Error {
    case noteNotFound
}
