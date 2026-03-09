import Foundation
import RipoDomain

public struct TemplatePreview: Sendable, Equatable {
    public var title: String
    public var body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

public struct TemplateEngineService: Sendable {
    private let templateRepository: TemplateRepository
    private let noteRepository: NoteRepository
    private let syncEngine: SyncEngine

    public init(
        templateRepository: TemplateRepository,
        noteRepository: NoteRepository,
        syncEngine: SyncEngine
    ) {
        self.templateRepository = templateRepository
        self.noteRepository = noteRepository
        self.syncEngine = syncEngine
    }

    @discardableResult
    public func createTemplate(
        ownerUserId: UUID,
        name: String,
        scope: TemplateScope,
        type: TemplateType,
        titleTemplate: String,
        bodyTemplate: String,
        now: Date = .now
    ) async throws -> TemplateDefinition {
        let template = TemplateDefinition(
            ownerUserId: ownerUserId,
            name: name,
            scope: scope,
            type: type,
            titleTemplate: titleTemplate,
            bodyTemplate: bodyTemplate,
            createdAt: now,
            updatedAt: now
        )
        try await templateRepository.upsert(template)
        return template
    }

    @discardableResult
    public func cloneTemplate(
        templateId: UUID,
        newName: String,
        now: Date = .now
    ) async throws -> TemplateDefinition {
        guard let source = try await templateRepository.template(by: templateId) else {
            throw TemplateEngineError.templateNotFound
        }

        var cloned = source
        cloned.id = UUID()
        cloned.name = newName
        cloned.createdAt = now
        cloned.updatedAt = now
        try await templateRepository.upsert(cloned)
        return cloned
    }

    @discardableResult
    public func updateTemplate(
        templateId: UUID,
        name: String,
        scope: TemplateScope,
        type: TemplateType,
        titleTemplate: String,
        bodyTemplate: String,
        now: Date = .now
    ) async throws -> TemplateDefinition {
        guard var template = try await templateRepository.template(by: templateId) else {
            throw TemplateEngineError.templateNotFound
        }

        template.name = name
        template.scope = scope
        template.type = type
        template.titleTemplate = titleTemplate
        template.bodyTemplate = bodyTemplate
        template.updatedAt = now
        try await templateRepository.upsert(template)
        return template
    }

    public func renderPreview(
        titleTemplate: String,
        bodyTemplate: String,
        variables: [String: String]
    ) -> TemplatePreview {
        TemplatePreview(
            title: render(titleTemplate, variables: variables),
            body: render(bodyTemplate, variables: variables)
        )
    }

    @discardableResult
    public func createNoteFromTemplate(
        templateId: UUID,
        ownerUserId: UUID,
        variables: [String: String],
        source: NoteSource = .manual,
        now: Date = .now
    ) async throws -> Note {
        guard let template = try await templateRepository.template(by: templateId) else {
            throw TemplateEngineError.templateNotFound
        }

        let renderedTitle = render(template.titleTemplate, variables: variables)
        let renderedBody = render(template.bodyTemplate, variables: variables)

        let note = Note(
            ownerUserId: ownerUserId,
            title: normalizedTitle(renderedTitle, fallbackBody: renderedBody),
            plainTextBody: renderedBody,
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

    private func render(_ raw: String, variables: [String: String]) -> String {
        variables.reduce(raw) { partial, pair in
            partial.replacingOccurrences(of: "{{\(pair.key)}}", with: pair.value)
        }
    }

    private func normalizedTitle(_ title: String, fallbackBody: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return String(trimmed.prefix(80))
        }
        return String((fallbackBody.split(separator: "\n").first.map(String.init) ?? "Untitled").prefix(80))
    }
}

public enum TemplateEngineError: Error {
    case templateNotFound
}
