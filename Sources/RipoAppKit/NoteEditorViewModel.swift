import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class NoteEditorViewModel: ObservableObject {
    @Published public private(set) var noteId: UUID?
    @Published public var title: String = ""
    @Published public var body: String = ""
    @Published public private(set) var toolbarError: String?
    @Published public private(set) var noteAttachments: [Attachment] = []
    @Published public var newAttachmentPath: String = ""
    @Published public private(set) var attachmentError: String?

    private let ownerUserId: UUID
    private let noteRepository: NoteRepository
    private let editorService: NoteEditorService
    private let toolbarViewModel: EditorToolbarViewModel
    private let attachmentRepository: AttachmentRepository?
    private let attachmentService: AttachmentService?

    public init(
        ownerUserId: UUID,
        noteRepository: NoteRepository,
        editorService: NoteEditorService,
        toolbarViewModel: EditorToolbarViewModel = EditorToolbarViewModel(),
        attachmentRepository: AttachmentRepository? = nil,
        attachmentService: AttachmentService? = nil
    ) {
        self.ownerUserId = ownerUserId
        self.noteRepository = noteRepository
        self.editorService = editorService
        self.toolbarViewModel = toolbarViewModel
        self.attachmentRepository = attachmentRepository
        self.attachmentService = attachmentService
    }

    public func open(noteId: UUID?) async throws {
        if let noteId,
           let note = try await noteRepository.note(by: noteId)
        {
            self.noteId = note.id
            title = note.title
            body = note.plainTextBody
            await loadAttachments()
            return
        }

        let newNote = try await editorService.createDraft(ownerUserId: ownerUserId)
        self.noteId = newNote.id
        title = newNote.title
        body = newNote.plainTextBody
        await loadAttachments()
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

    public func addImageAttachment() async {
        guard let noteId,
              let attachmentService else { return }
        do {
            _ = try await attachmentService.addImageToNote(noteId: noteId, localPath: newAttachmentPath)
            newAttachmentPath = ""
            await loadAttachments()
            attachmentError = nil
        } catch {
            attachmentError = String(describing: error)
        }
    }

    public func removeAttachment(_ attachmentId: UUID) async {
        guard let attachmentService else { return }
        do {
            try await attachmentService.removeAttachment(attachmentId)
            await loadAttachments()
            attachmentError = nil
        } catch {
            attachmentError = String(describing: error)
        }
    }

    public func loadAttachments() async {
        guard let noteId,
              let attachmentRepository else
        {
            noteAttachments = []
            return
        }

        do {
            noteAttachments = try await attachmentRepository.attachments(ownerType: .note, ownerId: noteId)
        } catch {
            attachmentError = String(describing: error)
        }
    }
}
