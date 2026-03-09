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

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService
    private let toolbarViewModel: EditorToolbarViewModel

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService,
        toolbarViewModel: EditorToolbarViewModel = EditorToolbarViewModel()
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
        self.toolbarViewModel = toolbarViewModel
    }

    public func load(scope: TemplateScope? = nil) async {
        do {
            templates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: scope)
            if selectedTemplateId == nil {
                selectedTemplateId = templates.first?.id
            }
            hydrateDraftFromSelection()
            refreshPreview()
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
}
