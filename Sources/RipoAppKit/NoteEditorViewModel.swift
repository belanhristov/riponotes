import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class NoteEditorViewModel: ObservableObject {
    @Published public private(set) var noteId: UUID?
    @Published public var title: String = ""
    @Published public var body: String = ""
    @Published public private(set) var toolbarError: String?

    private let ownerUserId: UUID
    private let noteRepository: NoteRepository
    private let editorService: NoteEditorService
    private let toolbarViewModel: EditorToolbarViewModel

    public init(
        ownerUserId: UUID,
        noteRepository: NoteRepository,
        editorService: NoteEditorService,
        toolbarViewModel: EditorToolbarViewModel = EditorToolbarViewModel()
    ) {
        self.ownerUserId = ownerUserId
        self.noteRepository = noteRepository
        self.editorService = editorService
        self.toolbarViewModel = toolbarViewModel
    }

    public func open(noteId: UUID?) async throws {
        if let noteId,
           let note = try await noteRepository.note(by: noteId)
        {
            self.noteId = note.id
            title = note.title
            body = note.plainTextBody
            return
        }

        let newNote = try await editorService.createDraft(ownerUserId: ownerUserId)
        self.noteId = newNote.id
        title = newNote.title
        body = newNote.plainTextBody
    }

    @discardableResult
    public func save() async throws -> Note {
        guard let noteId else { throw NoteEditorError.noteNotFound }
        return try await editorService.save(noteId: noteId, title: title, body: body)
    }

    public func applyToolbar(_ command: EditorCommand, lineRange: ClosedRange<Int>? = nil) {
        do {
            body = try toolbarViewModel.apply(command, text: body, lineRange: lineRange)
            toolbarError = nil
        } catch {
            toolbarError = String(describing: error)
        }
    }
}
