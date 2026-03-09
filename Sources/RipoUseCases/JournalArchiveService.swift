import Foundation
import RipoDomain

public struct JournalMemoryCard: Sendable, Equatable, Identifiable {
    public var id: UUID { noteId }
    public var noteId: UUID
    public var title: String
    public var excerpt: String
    public var moodTag: String?
    public var dayPartTag: String?
    public var createdAt: Date
    public var isEncrypted: Bool

    public init(
        noteId: UUID,
        title: String,
        excerpt: String,
        moodTag: String?,
        dayPartTag: String?,
        createdAt: Date,
        isEncrypted: Bool
    ) {
        self.noteId = noteId
        self.title = title
        self.excerpt = excerpt
        self.moodTag = moodTag
        self.dayPartTag = dayPartTag
        self.createdAt = createdAt
        self.isEncrypted = isEncrypted
    }
}

public struct JournalArchiveService: Sendable {
    private let noteRepository: NoteRepository

    public init(noteRepository: NoteRepository) {
        self.noteRepository = noteRepository
    }

    public func timeline(ownerUserId: UUID, monthAnchor: Date? = nil) async throws -> [JournalMemoryCard] {
        let notes = try await noteRepository.activeNotes(ownerUserId: ownerUserId)
        let journalNotes = notes.filter { $0.tags.contains("journal") }

        let filtered: [Note]
        if let monthAnchor {
            let cal = Calendar.current
            filtered = journalNotes.filter { cal.isDate($0.createdAt, equalTo: monthAnchor, toGranularity: .month) }
        } else {
            filtered = journalNotes
        }

        return filtered
            .map(makeCard(note:))
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private func makeCard(note: Note) -> JournalMemoryCard {
        let moodCandidates = Set(["joyful", "sad", "calm", "anxious", "excited", "tired"])
        let dayPartCandidates = Set(["daytime", "night"])
        let mood = note.tags.first(where: { moodCandidates.contains($0) })
        let dayPart = note.tags.first(where: { dayPartCandidates.contains($0) })
        let encrypted = note.plainTextBody.hasPrefix("[ENCRYPTED]\n") || note.tags.contains("encrypted")

        let excerpt: String
        if encrypted {
            excerpt = "Encrypted entry - unlock to preview"
        } else {
            excerpt = note.plainTextBody
                .split(separator: "\n")
                .prefix(2)
                .joined(separator: " ")
        }

        return JournalMemoryCard(
            noteId: note.id,
            title: note.title,
            excerpt: excerpt,
            moodTag: mood,
            dayPartTag: dayPart,
            createdAt: note.createdAt,
            isEncrypted: encrypted
        )
    }
}
