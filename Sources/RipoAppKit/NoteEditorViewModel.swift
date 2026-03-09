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
    @Published public private(set) var noteTags: [String] = []
    @Published public var newNoteTagText: String = ""
    @Published public var attachmentTagInputs: [UUID: String] = [:]
    @Published public private(set) var tagError: String?
    @Published public private(set) var convertMessage: String?
    @Published public private(set) var convertError: String?

    @Published public var convertReminderAt: Date = .now.addingTimeInterval(60 * 60)
    @Published public var convertListTitle: String = ""
    @Published public var convertListItemsText: String = ""
    @Published public var convertContactIdentifier: String = ""
    @Published public var convertContactDisplayName: String = ""
    @Published public var convertLocationLabel: String = ""
    @Published public var convertLatitude: String = ""
    @Published public var convertLongitude: String = ""
    @Published public var convertRadiusMeters: String = "200"

    private let ownerUserId: UUID
    private let noteRepository: NoteRepository
    private let editorService: NoteEditorService
    private let toolbarViewModel: EditorToolbarViewModel
    private let attachmentRepository: AttachmentRepository?
    private let attachmentService: AttachmentService?
    private let taggingService: TaggingService?
    private let convertService: ConvertNoteService?

    public init(
        ownerUserId: UUID,
        noteRepository: NoteRepository,
        editorService: NoteEditorService,
        toolbarViewModel: EditorToolbarViewModel = EditorToolbarViewModel(),
        attachmentRepository: AttachmentRepository? = nil,
        attachmentService: AttachmentService? = nil,
        taggingService: TaggingService? = nil,
        convertService: ConvertNoteService? = nil
    ) {
        self.ownerUserId = ownerUserId
        self.noteRepository = noteRepository
        self.editorService = editorService
        self.toolbarViewModel = toolbarViewModel
        self.attachmentRepository = attachmentRepository
        self.attachmentService = attachmentService
        self.taggingService = taggingService
        self.convertService = convertService
    }

    public func open(noteId: UUID?) async throws {
        if let noteId,
           let note = try await noteRepository.note(by: noteId)
        {
            self.noteId = note.id
            title = note.title
            body = note.plainTextBody
            noteTags = note.tags.sorted()
            await loadAttachments()
            return
        }

        let newNote = try await editorService.createDraft(ownerUserId: ownerUserId)
        self.noteId = newNote.id
        title = newNote.title
        body = newNote.plainTextBody
        noteTags = newNote.tags.sorted()
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
            attachmentTagInputs = noteAttachments.reduce(into: [:]) { partial, attachment in
                partial[attachment.id] = ""
            }
        } catch {
            attachmentError = String(describing: error)
        }
    }

    public func addNoteTag() async {
        guard let noteId,
              let taggingService else { return }
        do {
            let updated = try await taggingService.addTagToNote(noteId: noteId, rawTag: newNoteTagText)
            noteTags = updated.tags.sorted()
            newNoteTagText = ""
            tagError = nil
        } catch {
            tagError = String(describing: error)
        }
    }

    public func removeNoteTag(_ tag: String) async {
        guard let noteId,
              let taggingService else { return }
        do {
            let updated = try await taggingService.removeTagFromNote(noteId: noteId, rawTag: tag)
            noteTags = updated.tags.sorted()
            tagError = nil
        } catch {
            tagError = String(describing: error)
        }
    }

    public func addAttachmentTag(attachmentId: UUID) async {
        guard let taggingService else { return }
        let rawTag = attachmentTagInputs[attachmentId] ?? ""
        do {
            let updated = try await taggingService.addTagToAttachment(attachmentId: attachmentId, rawTag: rawTag)
            noteAttachments = noteAttachments.map { $0.id == updated.id ? updated : $0 }
            attachmentTagInputs[attachmentId] = ""
            tagError = nil
        } catch {
            tagError = String(describing: error)
        }
    }

    public func removeAttachmentTag(attachmentId: UUID, tag: String) async {
        guard let taggingService else { return }
        do {
            let updated = try await taggingService.removeTagFromAttachment(attachmentId: attachmentId, rawTag: tag)
            noteAttachments = noteAttachments.map { $0.id == updated.id ? updated : $0 }
            tagError = nil
        } catch {
            tagError = String(describing: error)
        }
    }

    public func clearEditorStateForPrivacy() {
        noteId = nil
        title = ""
        body = ""
        noteAttachments = []
        newAttachmentPath = ""
        noteTags = []
        newNoteTagText = ""
        attachmentTagInputs = [:]
        toolbarError = nil
        attachmentError = nil
        tagError = nil
        convertMessage = nil
        convertError = nil
    }

    public func convertToReminder() async {
        guard let noteId,
              let convertService else { return }
        do {
            let reminder = try await convertService.convertToReminder(
                noteId: noteId,
                triggerAt: convertReminderAt
            )
            convertMessage = "Reminder created at \(reminder.triggerAt.formatted())"
            convertError = nil
        } catch {
            convertError = String(describing: error)
        }
    }

    public func convertToList() async {
        guard let noteId,
              let convertService else { return }
        do {
            let lines = convertListItemsText.split(separator: "\n").map(String.init)
            let list = try await convertService.convertToList(
                noteId: noteId,
                title: convertListTitle.isEmpty ? (title.isEmpty ? "New List" : title) : convertListTitle,
                items: lines
            )
            convertMessage = "List created: \(list.title)"
            convertError = nil
        } catch {
            convertError = String(describing: error)
        }
    }

    public func convertToContactLink() async {
        guard let noteId,
              let convertService else { return }
        do {
            let link = try await convertService.convertToContactLink(
                noteId: noteId,
                contactIdentifier: convertContactIdentifier,
                displayNameSnapshot: convertContactDisplayName
            )
            convertMessage = "Contact linked: \(link.displayNameSnapshot)"
            convertError = nil
        } catch {
            convertError = String(describing: error)
        }
    }

    public func convertToLocationLink() async {
        guard let noteId,
              let convertService else { return }
        do {
            let link = try await convertService.convertToLocationLink(
                noteId: noteId,
                latitude: Double(convertLatitude) ?? 0,
                longitude: Double(convertLongitude) ?? 0,
                radiusMeters: Double(convertRadiusMeters) ?? 200,
                label: convertLocationLabel.isEmpty ? "Pinned Place" : convertLocationLabel
            )
            convertMessage = "Location linked: \(link.label)"
            convertError = nil
        } catch {
            convertError = String(describing: error)
        }
    }
}
