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
    @Published public private(set) var contextSuggestion: ContextSuggestion?
    @Published public var selectedMood: JourneyMood = .calm
    @Published public var selectedDayPart: JourneyDayPart = .daytime
    @Published public var useAutoTemplate: Bool = true
    @Published public var encryptOnSave: Bool = false
    @Published public private(set) var decryptedPreviewText: String?

    public let noteEditorViewModel: NoteEditorViewModel

    private let ownerUserId: UUID
    private let templateRepository: TemplateRepository
    private let templateEngine: TemplateEngineService
    private let securityService: JournalSecurityService?
    private let contextSuggestionService: ContextSuggestionService?
    private let journeyTemplateService: JourneyTemplateService

    public init(
        ownerUserId: UUID,
        templateRepository: TemplateRepository,
        templateEngine: TemplateEngineService,
        noteEditorViewModel: NoteEditorViewModel,
        securityService: JournalSecurityService? = nil,
        contextSuggestionService: ContextSuggestionService? = nil,
        journeyTemplateService: JourneyTemplateService = JourneyTemplateService()
    ) {
        self.ownerUserId = ownerUserId
        self.templateRepository = templateRepository
        self.templateEngine = templateEngine
        self.noteEditorViewModel = noteEditorViewModel
        self.securityService = securityService
        self.contextSuggestionService = contextSuggestionService
        self.journeyTemplateService = journeyTemplateService
    }

    public func load() async {
        do {
            journalTemplates = try await templateRepository.templates(ownerUserId: ownerUserId, scope: .journal)
            if selectedTemplateId == nil {
                selectedTemplateId = journalTemplates.first?.id
            }
            try await refreshSecurityStatus()
            applyLockStateToEditor()
            await refreshContextSuggestion()
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
            if useAutoTemplate {
                let draft = journeyTemplateService.makeDraft(
                    mood: selectedMood,
                    dayPart: selectedDayPart
                )
                noteEditorViewModel.title = draft.title
                noteEditorViewModel.body = draft.body
                await noteEditorViewModel.addTags(draft.tags + ["journal"])
            } else {
                await noteEditorViewModel.addTags(["journal"])
            }
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
            applyLockStateToEditor()
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
            applyLockStateToEditor()
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
            applyLockStateToEditor()
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
            applyLockStateToEditor()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func refreshContextSuggestion() async {
        guard let contextSuggestionService else { return }
        do {
            contextSuggestion = try await contextSuggestionService.suggest()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func startFromContextSuggestion() async {
        if isLockEnabled && !isUnlocked {
            errorMessage = String(describing: JournalSecurityError.locked)
            return
        }
        guard let contextSuggestion else { return }
        do {
            try await noteEditorViewModel.open(noteId: nil)
            noteEditorViewModel.title = contextSuggestion.title
            noteEditorViewModel.body = contextSuggestion.body
            _ = try await noteEditorViewModel.save()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func saveCurrentEntry() async {
        do {
            if encryptOnSave {
                guard let securityService else {
                    errorMessage = "Encryption requires journal lock setup."
                    return
                }
                let status = try await securityService.status()
                guard status.isLockEnabled else {
                    errorMessage = "Enable journal lock before encrypted save."
                    return
                }
                guard status.isUnlocked else {
                    errorMessage = String(describing: JournalSecurityError.locked)
                    return
                }
            let encrypted = try await securityService.encrypt(noteEditorViewModel.body)
            noteEditorViewModel.body = "[ENCRYPTED]\n\(encrypted)"
            await noteEditorViewModel.addTags(["encrypted"])
            }
            _ = try await noteEditorViewModel.save()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public var isCurrentEntryEncrypted: Bool {
        noteEditorViewModel.body.hasPrefix("[ENCRYPTED]\n")
    }

    public func decryptCurrentEntryIfNeeded() async {
        guard isCurrentEntryEncrypted else { return }
        guard let securityService else {
            errorMessage = "Journal security service unavailable."
            return
        }

        do {
            let status = try await securityService.status()
            guard status.isLockEnabled else {
                errorMessage = "Enable journal lock to decrypt this entry."
                return
            }
            guard status.isUnlocked else {
                errorMessage = String(describing: JournalSecurityError.locked)
                return
            }

            let payload = noteEditorViewModel.body.replacingOccurrences(of: "[ENCRYPTED]\n", with: "")
            let plaintext = try await securityService.decrypt(payload)
            noteEditorViewModel.body = plaintext
            decryptedPreviewText = nil
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    public func decryptCurrentEntryToPreview() async {
        guard isCurrentEntryEncrypted else {
            decryptedPreviewText = nil
            return
        }
        guard let securityService else {
            errorMessage = "Journal security service unavailable."
            return
        }

        do {
            let status = try await securityService.status()
            guard status.isLockEnabled else {
                errorMessage = "Enable journal lock to decrypt this entry."
                return
            }
            guard status.isUnlocked else {
                errorMessage = String(describing: JournalSecurityError.locked)
                return
            }

            let payload = noteEditorViewModel.body.replacingOccurrences(of: "[ENCRYPTED]\n", with: "")
            let plaintext = try await securityService.decrypt(payload)
            decryptedPreviewText = plaintext
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

    private func applyLockStateToEditor() {
        if isLockEnabled && !isUnlocked {
            noteEditorViewModel.clearEditorStateForPrivacy()
        }
    }
}
