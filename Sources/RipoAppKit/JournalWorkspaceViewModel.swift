import Foundation
import RipoDomain
import RipoUseCases

@MainActor
public final class JournalWorkspaceViewModel: ObservableObject {
    @Published public private(set) var journalTemplates: [TemplateDefinition] = []
    @Published public var selectedTemplateId: UUID?
    @Published public var templateVariablesText: String = "date=2026-03-09\nmood=Calm\nplace=Home"
    @Published public var errorMessage: String?
    @Published public private(set) var isLockEnabled: Bool = false
    @Published public private(set) var isUnlocked: Bool = true

    public let noteEditorViewModel: NoteEditorViewModel

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService
    private let securityService: JournalSecurityService?

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService,
        noteEditorViewModel: NoteEditorViewModel,
        securityService: JournalSecurityService? = nil
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
        self.noteEditorViewModel = noteEditorViewModel
        self.securityService = securityService
    }

    public func load() async {
        do {
            journalTemplates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: .journal)
            if selectedTemplateId == nil {
                selectedTemplateId = journalTemplates.first?.id
            }
            try await refreshSecurityStatus()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func startBlankEntry() async {
        if isLockEnabled && !isUnlocked {
            errorMessage = String(describing: JournalSecurityError.locked)
            return
        }
        do {
            try await noteEditorViewModel.open(noteId: nil)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func startFromSelectedTemplate() async {
        if isLockEnabled && !isUnlocked {
            errorMessage = String(describing: JournalSecurityError.locked)
            return
        }
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

    public func enableLock(passcode: String) async {
        guard let securityService else { return }
        do {
            try await securityService.enableLock(passcode: passcode)
            try await refreshSecurityStatus()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func unlockWithPasscode(_ passcode: String) async {
        guard let securityService else { return }
        do {
            try await securityService.unlockWithPasscode(passcode)
            try await refreshSecurityStatus()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func unlockWithBiometrics() async {
        guard let securityService else { return }
        do {
            try await securityService.unlockWithBiometrics()
            try await refreshSecurityStatus()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func lockJournal() async {
        guard let securityService else { return }
        do {
            try await securityService.lock()
            try await refreshSecurityStatus()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
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

    private func refreshSecurityStatus() async throws {
        guard let securityService else {
            isLockEnabled = false
            isUnlocked = true
            return
        }
        let status = try await securityService.status()
        isLockEnabled = status.isLockEnabled
        isUnlocked = status.isUnlocked
    }
}
