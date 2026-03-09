import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class TemplateStudioViewModel: ObservableObject {
    @Published public private(set) var templates: [TemplateDefinition] = []
    @Published public var selectedTemplateId: UUID?
    @Published public var errorMessage: String?

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
    }

    public func load(scope: TemplateScope? = nil) async {
        do {
            templates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: scope)
            if selectedTemplateId == nil {
                selectedTemplateId = templates.first?.id
            }
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func createTemplate(
        name: String,
        scope: TemplateScope,
        type: TemplateType,
        titleTemplate: String,
        bodyTemplate: String
    ) async {
        do {
            let template = try await templateEngine.createTemplate(
                ownerUserId: ownerUserId,
                name: name,
                scope: scope,
                type: type,
                titleTemplate: titleTemplate,
                bodyTemplate: bodyTemplate
            )
            await load(scope: nil)
            selectedTemplateId = template.id
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
    }
}
