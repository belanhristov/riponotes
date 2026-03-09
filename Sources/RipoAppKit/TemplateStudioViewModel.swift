import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class TemplateStudioViewModel: ObservableObject {
    @Published public private(set) var templates: [TemplateDefinition] = []
    @Published public var selectedTemplateId: UUID?
    @Published public var errorMessage: String?
    @Published public var draftName: String = ""
    @Published public var draftScope: TemplateScope = .note
    @Published public var draftType: TemplateType = .custom
    @Published public var draftTitleTemplate: String = "{{title}}"
    @Published public var draftBodyTemplate: String = "{{body}}"
    @Published public private(set) var previewTitle: String = ""
    @Published public private(set) var previewBody: String = ""
    @Published public var previewVariablesText: String = "title=Quick Start\nbody=Start writing..."
    @Published public private(set) var templateAttachments: [Attachment] = []
    @Published public var newAttachmentPath: String = ""

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService
    private let toolbarViewModel: EditorToolbarViewModel
    private let attachmentRepository: AttachmentRepository?
    private let attachmentService: AttachmentService?

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService,
        toolbarViewModel: EditorToolbarViewModel = EditorToolbarViewModel(),
        attachmentRepository: AttachmentRepository? = nil,
        attachmentService: AttachmentService? = nil
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
        self.toolbarViewModel = toolbarViewModel
        self.attachmentRepository = attachmentRepository
        self.attachmentService = attachmentService
    }

    public func load(scope: TemplateScope? = nil) async {
        do {
            templates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: scope)
            if selectedTemplateId == nil {
                selectedTemplateId = templates.first?.id
            }
            hydrateDraftFromSelection()
            refreshPreview()
            await loadSelectedTemplateAttachments()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func createTemplateFromDraft() async {
        do {
            let template = try await templateEngine.createTemplate(
                ownerUserId: ownerUserId,
                name: draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Template" : draftName,
                scope: draftScope,
                type: draftType,
                titleTemplate: draftTitleTemplate,
                bodyTemplate: draftBodyTemplate
            )
            await load(scope: nil)
            selectedTemplateId = template.id
            hydrateDraftFromSelection()
            refreshPreview()
            await loadSelectedTemplateAttachments()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func cloneSelectedTemplate(newName: String) async {
        guard let selectedTemplateId else { return }
        do {
            let cloned = try await templateEngine.cloneTemplate(templateId: selectedTemplateId, newName: newName)
            await load(scope: nil)
            self.selectedTemplateId = cloned.id
            hydrateDraftFromSelection()
            refreshPreview()
            await loadSelectedTemplateAttachments()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func saveSelectedTemplateEdits() async {
        guard let selectedTemplateId else { return }
        do {
            _ = try await templateEngine.updateTemplate(
                templateId: selectedTemplateId,
                name: draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Template" : draftName,
                scope: draftScope,
                type: draftType,
                titleTemplate: draftTitleTemplate,
                bodyTemplate: draftBodyTemplate
            )
            await load(scope: nil)
            self.selectedTemplateId = selectedTemplateId
            hydrateDraftFromSelection()
            refreshPreview()
            await loadSelectedTemplateAttachments()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    @discardableResult
    public func createNoteFromSelectedTemplate(variables: [String: String]) async -> Note? {
        guard let selectedTemplateId else { return nil }
        do {
            let note = try await templateEngine.createNoteFromTemplate(
                templateId: selectedTemplateId,
                ownerUserId: ownerUserId,
                variables: variables
            )
            errorMessage = nil
            return note
        } catch {
            errorMessage = String(describing: error)
            return nil
        }
    }

    public func selectTemplate(_ id: UUID?) {
        selectedTemplateId = id
        hydrateDraftFromSelection()
        refreshPreview()
        Task { await loadSelectedTemplateAttachments() }
    }

    public func applyToolbarToDraftBody(_ command: EditorCommand, lineRange: ClosedRange<Int>? = nil) {
        do {
            draftBodyTemplate = try toolbarViewModel.apply(command, text: draftBodyTemplate, lineRange: lineRange)
            refreshPreview()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func refreshPreview() {
        let preview = templateEngine.renderPreview(
            titleTemplate: draftTitleTemplate,
            bodyTemplate: draftBodyTemplate,
            variables: parsedVariables(previewVariablesText)
        )
        previewTitle = preview.title
        previewBody = preview.body
    }

    public func addImageToSelectedTemplate() async {
        guard let selectedTemplateId,
              let attachmentService else { return }
        do {
            _ = try await attachmentService.addImageToTemplate(
                templateId: selectedTemplateId,
                localPath: newAttachmentPath
            )
            newAttachmentPath = ""
            await loadSelectedTemplateAttachments()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func removeAttachment(_ attachmentId: UUID) async {
        guard let attachmentService else { return }
        do {
            try await attachmentService.removeAttachment(attachmentId)
            await loadSelectedTemplateAttachments()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func hydrateDraftFromSelection() {
        guard let selectedTemplateId,
              let selected = templates.first(where: { $0.id == selectedTemplateId }) else
        {
            return
        }
        draftName = selected.name
        draftScope = selected.scope
        draftType = selected.type
        draftTitleTemplate = selected.titleTemplate
        draftBodyTemplate = selected.bodyTemplate
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

    private func loadSelectedTemplateAttachments() async {
        guard let attachmentRepository,
              let selectedTemplateId else
        {
            templateAttachments = []
            return
        }

        do {
            templateAttachments = try await attachmentRepository.attachments(
                ownerType: .template,
                ownerId: selectedTemplateId
            )
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
