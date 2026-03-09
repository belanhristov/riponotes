import Foundation
import Testing
@testable import RipoAppKit
@testable import RipoData
@testable import RipoDomain
@testable import RipoUseCases

struct RipoCoreTests {
    @Test
    func quickNoteDefaultsToInboxAndQueuesSyncJob() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let engine = QuickNoteEngine(noteRepository: repo, syncEngine: sync)

        let userId = UUID()
        let note = try await engine.createNote(
            QuickNoteInput(ownerUserId: userId, text: "Buy milk\n2L", source: .widget)
        )

        #expect(note.folderId == nil)
        #expect(note.title == "Buy milk")

        let inbox = try await repo.inboxNotes(ownerUserId: userId)
        #expect(inbox.count == 1)

        let jobs = try await sync.pendingJobs()
        #expect(jobs.count == 1)
        #expect(jobs.first?.entityId == note.id)
        #expect(jobs.first?.operation == .create)
    }

    @Test
    func convertNoteCreatesAndSchedulesReminder() async throws {
        let reminderRepo = InMemoryReminderRepository()
        let scheduler = InMemoryReminderScheduler()
        let convert = ConvertNoteService(reminderRepository: reminderRepo, reminderScheduler: scheduler)

        let noteId = UUID()
        let trigger = Date(timeIntervalSince1970: 2_000_000_000)
        let reminder = try await convert.convertToReminder(
            noteId: noteId,
            triggerAt: trigger,
            type: .alarm,
            priority: .critical,
            repeatRule: "FREQ=WEEKLY;BYDAY=MO"
        )

        let list = try await reminderRepo.reminders(for: noteId)
        #expect(list.count == 1)
        #expect(list.first?.type == .alarm)
        #expect(list.first?.priority == .critical)

        let scheduled = await scheduler.scheduledReminder(reminderId: reminder.id)
        #expect(scheduled != nil)
        #expect(scheduled?.triggerAt == trigger)
    }

    @Test
    func featureFlagsBootstrapMatchesProductDecision() {
        let flags = FeatureFlags.bootstrap

        #expect(flags[.googleSignIn] == false)
        #expect(flags[.outlookIntegration] == false)
        #expect(flags[.teamWorkspaces] == false)
        #expect(flags[.aiSummary] == false)
        #expect(flags[.mailCaptureAdvanced] == false)
        #expect(flags[.androidSyncCompat] == true)
    }

    @MainActor
    @Test
    func inboxViewModelCreatesQuickNoteAndSelectsIt() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let userId = UUID()

        let quickNote = QuickNoteEngine(noteRepository: repo, syncEngine: sync)
        let vm = InboxViewModel(ownerUserId: userId, noteRepository: repo, quickNoteEngine: quickNote)

        let created = try await vm.addQuickNote(text: "Plan weekend walk", source: .manual)

        #expect(vm.notes.count == 1)
        #expect(vm.selectedNoteId == created.id)
        #expect(vm.notes.first?.title == "Plan weekend walk")
    }

    @MainActor
    @Test
    func noteEditorViewModelCreatesDraftAndSavesBody() async throws {
        let repo = InMemoryNoteRepository()
        let sync = InMemorySyncEngine()
        let userId = UUID()

        let service = NoteEditorService(noteRepository: repo, syncEngine: sync)
        let vm = NoteEditorViewModel(ownerUserId: userId, noteRepository: repo, editorService: service)

        try await vm.open(noteId: nil)
        vm.title = ""
        vm.body = "Daily reflection\nToday I learned..."
        let saved = try await vm.save()

        #expect(saved.title == "Daily reflection")
        #expect(saved.plainTextBody.contains("Today I learned"))

        let jobs = try await sync.pendingJobs()
        #expect(jobs.count == 2) // create draft + update on save
    }

    #if canImport(SwiftData)
    @Test
    func swiftDataRepositorySupportsCrudAndSearch() async throws {
        let repo = try SwiftDataNoteRepository(inMemory: true)
        let userId = UUID()

        let note = Note(
            ownerUserId: userId,
            title: "Walk",
            plainTextBody: "Sunny weather at the beach",
            source: .manual,
            tags: ["health", "outdoor"]
        )

        try await repo.create(note)

        let inbox = try await repo.inboxNotes(ownerUserId: userId)
        #expect(inbox.count == 1)

        let matched = try await repo.search(ownerUserId: userId, query: "beach")
        #expect(matched.count == 1)
        #expect(matched.first?.id == note.id)

        try await repo.softDelete(noteId: note.id, deletedAt: .now)
        let afterDelete = try await repo.inboxNotes(ownerUserId: userId)
        #expect(afterDelete.isEmpty)
    }
    #endif
}
