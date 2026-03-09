import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class JournalWorkspaceViewModel: ObservableObject {
    @Published public private(set) var journalTemplates: [TemplateDefinition] = []
    @Published public var selectedTemplateId: UUID?
    @Published public var templateVariablesText: String = "date=2026-03-09\nmood=Calm\nplace=Home"
    @Published public var errorMessage: String?

    public let noteEditorViewModel: NoteEditorViewModel

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService,
        noteEditorViewModel: NoteEditorViewModel
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
        self.noteEditorViewModel = noteEditorViewModel
    }

    public func load() async {
        do {
            journalTemplates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: .journal)
            if selectedTemplateId == nil {
                selectedTemplateId = journalTemplates.first?.id
            }
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func startBlankEntry() async {
        do {
            try await noteEditorViewModel.open(noteId: nil)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func startFromSelectedTemplate() async {
        guard let selectedTemplateId else { return }
        do {
            let note = try await templateEngine.createNoteFromTemplate(
                templateId: selectedTemplateId,
                ownerUserId: ownerUserId,
                variables: parsedVariables(templateVariablesText)
            )
            try await noteEditorViewModel.open(noteId: note.id)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func selectTemplate(_ id: UUID?) {
        selectedTemplateId = id
    }

    private func parsedVariables(_ text: String) -> [String: String] {
        var output: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let raw = String(line)
            guard let idx = raw.firstIndex(of: "=") else { continue }
            let key = raw[..<idx].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = raw[raw.index(after: idx)...].trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                output[key] = value
            }
        }
        return output
    }
}
