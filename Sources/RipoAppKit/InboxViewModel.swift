import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class InboxViewModel: ObservableObject {
    @Published public private(set) var notes: [Note] = []
    @Published public private(set) var selectedNoteId: UUID?
    @Published public var brainDumpText: String = ""
    @Published public private(set) var brainDumpError: String?

    private let ownerUserId: UUID
    private let noteRepository: NoteRepository
    private let quickNoteEngine: QuickNoteEngine

    public init(ownerUserId: UUID, noteRepository: NoteRepository, quickNoteEngine: QuickNoteEngine) {
        self.ownerUserId = ownerUserId
        self.noteRepository = noteRepository
        self.quickNoteEngine = quickNoteEngine
    }

    public func loadInbox() async throws {
        notes = try await noteRepository.inboxNotes(ownerUserId: ownerUserId)
        if selectedNoteId == nil {
            selectedNoteId = notes.first?.id
        }
    }

    @discardableResult
    public func addQuickNote(text: String, source: NoteSource = .manual) async throws -> Note {
        let note = try await quickNoteEngine.createNote(
            QuickNoteInput(ownerUserId: ownerUserId, text: text, source: source)
        )
        try await loadInbox()
        selectedNoteId = note.id
        return note
    }

    public func select(noteId: UUID?) {
        selectedNoteId = noteId
    }

    @discardableResult
    public func submitBrainDump(source: NoteSource = .manual) async throws -> Note? {
        let trimmed = brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            brainDumpError = "Brain dump is empty."
            return nil
        }

        let created = try await addQuickNote(text: trimmed, source: source)
        brainDumpText = ""
        brainDumpError = nil
        return created
    }
}
